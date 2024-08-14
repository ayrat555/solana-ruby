# frozen_string_literal: true

module SolanaRuby
  module HttpMethods
    module BlockMethods

      def get_blocks(start_slot, end_slot)
        params = [start_slot, end_slot]
        block_info = request('getBlocks', params)
        block_info['result']
      end

      def get_block(slot, options = {})
        params = [slot, options]
        block_info = request('getBlock', params)
        block_info['result']
      end

      def get_block_production
        block_info = request('getBlockProduction')
        block_info['result']
      end

      def get_block_time(slot)
        block_info = request('getBlockTime', [slot])
        block_info['result']
      end

      def get_block_signatures(slot, options = {})
        block_info = get_block(slot, options)
        block_signatures(block_info)
      end

      def get_cluster_nodes
        cluster_nodes_info = request('getClusterNodes')
        cluster_nodes_info['result']
      end

      def get_confirmed_block(slot, options = {})
        params = [slot, options]
        block_info = request('getConfirmedBlock', params)
        block_info["result"]
      end

      def get_confirmed_block_signatures(slot)
        block_info = get_confirmed_block(slot)
        block_signatures(block_info)
      end

      private

      def block_signatures(block_info)
        signatures = block_info['transactions'][0]['transaction']['signatures']
        block_info.delete('transactions')
        block_info.delete('rewards')
        block_info.merge({ 
          signatures: signatures
        })
      end
    end
  end
end
