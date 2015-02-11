require 'spec_helper'

describe HubspotEndpoint do

  let(:msg) do
    {
      request_id: '1234567',
      parameters: {
        access_token: 'eac97693-26be-11e3-9a20-856fcdde1271',
        refresh_token: 'eac6b772-26be-11e3-9a20-856fcdde1271',
        portal_id: '291274'
      }
    }.merge(Hub::Samples::Order.object).with_indifferent_access
  end

  def auth
    {'HTTP_X_HUB_TOKEN' => 'x123', "CONTENT_TYPE" => "application/json"}
  end

  def app
    HubspotEndpoint
  end

  it 'updates or creates a contact in hubspot' do
    VCR.use_cassette('updated_order_import') do
      post '/contact_import', msg.to_json, auth
      last_response.status.should == 200
      last_response.body.should match(/1234567/)
    end
  end
end