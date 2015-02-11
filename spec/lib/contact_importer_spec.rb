require 'spec_helper'

describe ContactImporter do

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

  it 'updates or creates a contact in hubspot' do
    VCR.use_cassette('updated_order_import') do

      importer = ContactImporter.new(msg[:parameters], msg, false)
      importer.import
      order = importer.order

      expect(order).to be
    end
  end

  it 'updates or creates a contact in hubspot' do
    VCR.use_cassette('canceled_order_import') do
      msg[:order][:status] = "cancelled"

      importer = ContactImporter.new(msg[:parameters], msg, false)
      importer.import
      order = importer.order

      expect(order).to be
    end
  end

  it 'updates or creates a contact in hubspot' do
    VCR.use_cassette('new_order_import') do
      importer = ContactImporter.new(msg[:parameters], msg, true)
      importer.import
      order = importer.order

      expect(order).to be
    end
  end
end
