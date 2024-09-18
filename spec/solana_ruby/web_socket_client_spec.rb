require 'spec_helper'

RSpec.describe SolanaRuby::WebSocketClient do
  let(:url) { 'wss://api.devnet.solana.com' }
  let(:ws_instance) { double('WebSocket::Client::Simple') }
  let(:new_ws_instance) { double('WebSocket::Client::Simple') }
  let(:client) { SolanaRuby::WebSocketClient.new(url, auto_reconnect: true, reconnect_delay: 1) }
  let(:generated_id) { '58984940-3093-44a1-a0fd-13abaddf57c7' }
  let(:account_address) { '9B5XszUGdMaxCZ7uSQhPzdks5ZQSmWxrmzCSvtJ6Ns6g' }
  let(:params) { [account_address] }
  let(:response) do
    {
      'jsonrpc' => '2.0',
      'id' => generated_id,
      'result' => 123456789
    }.to_json
  end

  before do
    # Mock WebSocket connection setup
    allow(WebSocket::Client::Simple).to receive(:connect)
      .and_return(ws_instance) # First call returns the initial ws_instance
      .and_return(new_ws_instance) # Subsequent calls return new_ws_instance

    # Mock the send method
    allow(ws_instance).to receive(:send)
    allow(new_ws_instance).to receive(:send)

    # Handle WebSocket events with explicit control
    allow(ws_instance).to receive(:on) do |event, &block|
      case event
      when :message
        @message_callback = block
      when :open
        @open_callback = block
      when :close
        @close_callback = block
      when :error
        @error_callback = block
      end
    end

    allow(new_ws_instance).to receive(:on) do |event, &block|
      case event
      when :message
        @message_callback = block
      when :open
        @open_callback = block
      when :close
        @close_callback = block
      when :error
        @error_callback = block
      end
    end

    # Mock SecureRandom to generate predictable IDs
    allow(SecureRandom).to receive(:uuid).and_return(generated_id)

    # Set initial WebSocket instance for client
    client.instance_variable_set(:@ws, ws_instance)
  end

  describe '#accountSubscribe' do
    it 'sends a subscription request with correct parameters' do
      client.subscribe('accountSubscribe', params)

      expected_message = {
        jsonrpc: '2.0',
        id: generated_id,
        method: 'accountSubscribe',
        params: params
      }.to_json

      expect(ws_instance).to have_received(:send).with(expected_message)
    end

    it 'handles received messages and triggers subscription callbacks' do
      callback = double('Callback')
      expect(callback).to receive(:call).with(123456789)

      client.subscribe('accountSubscribe', params) do |result|
        callback.call(result)
      end

      # Simulate WebSocket message event
      @message_callback.call(double('Message', data: response))
    end

    it 'does not reconnect if auto_reconnect is false' do
      client_with_no_reconnect = SolanaRuby::WebSocketClient.new(url, auto_reconnect: false)
      allow(client_with_no_reconnect).to receive(:attempt_reconnect)

      # Simulate connection close
      @close_callback.call(nil) if @close_callback

      expect(client_with_no_reconnect).not_to have_received(:attempt_reconnect)
    end

    it 'handles error events gracefully and reconnects if necessary' do
      allow(client).to receive(:attempt_reconnect)

      # Simulate error event triggering a reconnect
      @error_callback.call(double('Error', inspect: 'Error'))

      expect(client).to have_received(:attempt_reconnect)
    end

    it 'unsubscribes correctly from the subscription' do
      subscription_id = client.subscribe('accountSubscribe', params)

      expected_unsubscribe_message = {
        jsonrpc: '2.0',
        id: SecureRandom.uuid,
        method: 'accountUnsubscribe',
        params: [subscription_id]
      }.to_json

      client.unsubscribe('accountUnsubscribe', subscription_id)

      expect(ws_instance).to have_received(:send).with(expected_unsubscribe_message)
    end
  end
end
