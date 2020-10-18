module ManageIQ
  module Providers
    module Nsxt
      module ToolbarOverrides
        class CloudNetworksCenter < ::ApplicationHelper::Toolbar::Override
          button_group(
          'cloud_network_vmdb',
          [
            select(
              :cloud_network_vmdb_choice,
              'fa fa-cog fa-lg',
              t = N_('Configuration'),
              t,
              :items => [
                button(
                  :cloud_network_new,
                  'pficon pficon-add-circle-o fa-lg',
                  t = N_('Add Cloud Network'),
                  t,
                  :data  => {
                    'function'      => 'sendDataWithRx',
                    'function-data' => {
                      :controller     => 'provider_dialogs',
                      :button         => :nsxt_create_cloud_network,
                      :modal_title    => N_('Add Cloud Network'),
                      :component_name => 'NsxtCloudNetworkForm'
                    }
                  },
                  :klass => ApplicationHelper::Button::CloudNetworkNew
                ),
                button(
                  :cloud_network_delete,
                  'pficon pficon-delete fa-lg',
                  t = N_('Delete selected Cloud Networks'),
                  t,
                  :url_parms    => 'main_div',
                  :send_checked => true,
                  :confirm      => N_('Warning: The selected Cloud Networks and ALL of their components will be permanently removed!'),
                  :enabled      => false,
                  :onwhen       => "1+",
                  :data         => {
                    'function'      => 'sendDataWithRx',
                    'function-data' => {
                      :type       => 'delete',
                      :controller => 'toolbarActions',
                      :payload    => {
                        :entity => 'cloud_networks',
                        :labels => {
                          :single   => _('Cloud Network'),
                          :multiple => _('Cloud Networks')
                        }
                      }
                    }.to_json
                  }
                )
              ]
            )
          ]
        )
        end
      end
    end
  end
end