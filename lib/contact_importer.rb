class ContactImporter
  include HTTParty
  base_uri 'https://api.hubapi.com'
  format :json

  def initialize(config, payload, create = true)
    @credentials = { access_token: config['access_token'], refresh_token: config['refresh_token'] }
    @order = payload[:order]
    @email = @order[:email]
    @status = @order[:status]
    @create = create
  end

  def order
    @order
  end

  def credentials
    @credentials
  end

  def import
    if hubspot_contact = get_hubspot_contact(@email)
      update_contact(hubspot_contact, @order)
    else
      create_contact(@order)
    end
  end

  def get_hubspot_contact(email)
    response = self.class.get("/contacts/v1/contact/email/#{email}/profile", query: @credentials,
        headers: { 'Content-Type' => 'application/json' })

    case response.code
    when 200
      response
    when 401
      @credentials = refresh_token(@credentials)

      ## Re-run query
      response = self.class.get("/contacts/v1/contact/email/#{email}/profile", query: @credentials,
        headers: { 'Content-Type' => 'application/json' })
    else
      raise "Something's wrong - 1"
    end

    ## This happens if the contact doesn't exist, not if the authentication fails
    response['message'] == 'resource not found' ? nil : response
  end

  def update_contact(existing_contact, order)
    @properties = []

    unless @order[:status] == "canceled"
      @properties = address_values(order)
      if existing_contact['properties']['initial_campaign']['value'].to_s.strip == ""
        @properties << { property: 'initial_campaign', value: order['campaign'] }
      end

      if existing_contact['properties']['initial_promotion']['value'].to_s.strip == ""
        @properties << { property: 'initial_promotion', value: order['promotion'] }
      end

      if existing_contact['properties']['account_creation_date']['value'].to_s.strip == ""
        @properties << { property: 'account_creation_date', value: hub_time(order['placed_on']) }
      end
    end

    @properties = @properties + recent_order_values(order, existing_contact) + update_total_revenues(existing_contact)

    contact_properties = { properties: @properties }.to_json

    begin
      self.class.post("/contacts/v1/contact/vid/#{existing_contact['vid']}/profile", query: @credentials, body: contact_properties,
        headers: { 'Content-Type' => 'application/json' }).parsed_response
    rescue Exception => e
      case e.status_code
      when 401
        @credentials = refresh_token(@credentials)

        ## Re-run the post
        self.class.post("/contacts/v1/contact/vid/#{existing_contact['vid']}/profile", query: @credentials, body: contact_properties,
          headers: { 'Content-Type' => 'application/json' }).parsed_response
      else
        raise "Something's wrong - 2"
      end
    end
  end

  def create_contact(order)
    @properties = address_values(order) + initial_order_values(order) + recent_order_values(order) + total_revenue_values(order)

    contact_properties = { properties: @properties }.to_json

    begin
      response = self.class.post('/contacts/v1/contact', query: @credentials, body: contact_properties,
          headers: { 'Content-Type' => 'application/x-www-form-urlencoded' })

    rescue Exception => e
      case e.status_code
      when 401
        @credentials = refresh_token(@credentials)

        ## Re-run the post
        response = self.class.post('/contacts/v1/contact', query: @credentials, body: contact_properties,
          headers: { 'Content-Type' => 'application/x-www-form-urlencoded' })
      else
        raise "Something's wrong - 3"
      end
    end
  end

  def refresh_token(credentials)
    hub_params = { refresh_token: credentials[:refresh_token], client_id: ENV['HUBSPOT_SPREE_CLIENT_ID'], grant_type: "refresh_token" }
    hub_response = self.class.post("/auth/v1/refresh", body: hub_params,
      headers: { 'Content-Type' => 'application/x-www-form-urlencoded' })
    ## Put new credentials into query
    credentials = { refresh_token: hub_response['refresh_token'], access_token: hub_response['access_token'] }

    credentials
  end

  def address_values(order)
    ## This gets called on new or updated contacts
    [ { property: 'firstname', value: order['billing_address']['firstname'] },
      { property: 'lastname', value: order['billing_address']['lastname'] },
      { property: 'email', value: order['email'] },
      { property: 'phone', value: order['billing_address']['phone'] },
      { property: 'address', value: address_merge(order) },
      { property: 'city', value: order['billing_address']['city'] },
      { property: 'state', value: abbr_or_name(order['billing_address']['state']) },
      { property: 'zip', value: order['billing_address']['zipcode'] },
      { property: 'country', value: order['billing_address']['country']['name'] },
      { property: 'lifecyclestage', value: 'customer' } ]
  end

  def initial_order_values(order)
    ## This only gets called on new contacts
    [ { property: 'initial_campaign', value: order['campaign'] },
      { property: 'initial_promotion', value: order['promotion'] },
      { property: 'account_creation_date', value: hub_time(order['placed_on']) } ]
  end

  def recent_order_values(order, existing_contact=nil)
    ## This gets called on new or updated contacts
    args = []
    if @order[:status] == "canceled"
      if existing_contact['properties']['mrt_order_number']['value'] == order['number']
        args = [ { property: 'mrt_campaign', value: nil },
          { property: 'mrt_promotion', value: nil },
          { property: 'mrt_date', value: nil },
          { property: 'mrt_order_number', value: nil },
          { property: 'mrt_total_shipping', value: nil },
          { property: 'mrt_total_tax', value: nil },
          { property: 'mrt_total_adjustment', value: nil },
          { property: 'mrt_total_revenue', value: nil } ]
      end
    else
      args = [ { property: 'mrt_campaign', value: order['campaign'] },
        { property: 'mrt_promotion', value: order['promotion'] },
        { property: 'mrt_date', value: hub_time(order['placed_on']) },
        { property: 'mrt_order_number', value: order['number'] },
        { property: 'mrt_total_shipping', value: order['ship_total'] },
        { property: 'mrt_total_tax', value: order['tax_total'] },
        { property: 'mrt_total_adjustment', value: order['adjustment_total'] },
        { property: 'mrt_total_revenue', value: order['total'] } ]
    end
    args
  end

  def total_revenue_values(order)
    ## This should only get called when the contact is new
    [ { property: 'total_order_shipping', value: order['ship_total'] },
      { property: 'total_order_tax', value: order['tax_total'] },
      { property: 'total_order_adjustment', value: order['adjustment_total'] },
      { property: 'total_order_revenue', value: order['total'] },
      { property: 'total_transactions', value: "1" } ]
  end

  def update_total_revenues(existing_contact)
    ## This only gets called on updating contacts
    previous_shipping = existing_contact['properties']['total_order_shipping']['value'].to_f
    previous_tax = existing_contact['properties']['total_order_tax']['value'].to_f
    previous_adjustment = existing_contact['properties']['total_order_adjustment']['value'].to_f
    previous_revenue = existing_contact['properties']['total_order_revenue']['value'].to_f
    previous_transactions = existing_contact['properties']['total_transactions']['value'].to_i

    if @order[:status] == "canceled"
      shipping = previous_shipping - @order['ship_total'].to_f
      tax = previous_tax - @order['tax_total'].to_f
      adjustment = previous_adjustment - @order['adjustment_total'].to_f
      revenue = previous_revenue - @order['total'].to_f
      transactions = previous_transactions - 1
    elsif @create
      shipping = previous_shipping + @order['ship_total'].to_f
      tax = previous_tax + @order['tax_total'].to_f
      adjustment = previous_adjustment + @order['adjustment_total'].to_f
      revenue = previous_revenue + @order['total'].to_f
      transactions = previous_transactions + 1
    else
      # how is this even working?
      # shipping = previous_shipping - @previous_order['totals']['shipping'].to_f + @order['totals']['shipping'].to_f
      # tax = previous_tax - @previous_order['totals']['tax'].to_f + @order['totals']['tax'].to_f
      # adjustment = previous_adjustment - @previous_order['totals']['adjustment'].to_f + @order['totals']['adjustment'].to_f
      # revenue = previous_revenue - @previous_order['totals']['order'].to_f + @order['totals']['order'].to_f
      # transactions = previous_transactions
    end

    args = [ { property: 'total_order_shipping', value: shipping },
      { property: 'total_order_tax', value: tax },
      { property: 'total_order_adjustment', value: adjustment },
      { property: 'total_order_revenue', value: revenue },
      { property: 'total_transactions', value: transactions } ]
    args
  end

  def abbr_or_name(state)
    state['abbr'].to_s.strip == "" ? state['name'] : state['abbr']
  end

  def address_merge(order)
    [order['address1'], order['address2']].compact.reject{|a| a == ""}.join(", ")
  end

  def hub_time(time_string)
    Time.parse(time_string).to_i*1000
  end
end
