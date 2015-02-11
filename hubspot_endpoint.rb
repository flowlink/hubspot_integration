require 'sinatra'
require 'endpoint_base'

Dir['./lib/*.rb'].each { |f| require f }

class HubspotEndpoint < EndpointBase::Sinatra::Base
  post '/contact_import' do
    begin
      importer = ContactImporter.new(@config, @payload)
      importer.import
      order = importer.order

      code = 200
      summary = "The contact for order number #{order['number']} was imported."
    rescue Exception => e
      code = 500
      summary = e.backtrace # e.message
    end

    result code, summary
  end
end
