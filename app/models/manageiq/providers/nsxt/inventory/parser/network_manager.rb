class ManageIQ::Providers::Nsxt::Inventory::Parser::NetworkManager < ManageIQ::Providers::Nsxt::Inventory::Parser
  def parse
    network_services
    network_routers
    cloud_networks
    security_groups
    security_policies
  end

  def network_services
    collector.services.each do |service|
      network_service = persister.network_services.find_or_build(service['id'])
      network_service.name = service['display_name']
      network_service.description = service['description']
      network_service_entries(service)
    end
  end

  def network_service_entries(service)
    service['service_entries'].each do |service_entry|
      id = "#{service['id']}-#{service_entry['id']}"
      network_service_entry = persister.network_service_entries.find_or_build(id)
      network_service_entry.name = service_entry['display_name']
      network_service_entry.network_service = persister.network_services.lazy_find(service['id'])
      if service_entry['resource_type'] == 'L4PortSetServiceEntry'
        network_service_entry.protocol = service_entry['l4_protocol']
        network_service_entry.source_ports = network_service_entry_ports(service_entry['source_ports'])
        network_service_entry.destination_ports = network_service_entry_ports(service_entry['destination_ports'])
      else
        network_service_entry.protocol = service_entry['protocol']
      end
    end
  end

  def network_service_entry_ports(ports)
    return 'ANY' if ports.empty?
    return ports.join(',')
  end

  def network_routers
    collector.tier_1s.each do |tier_1|
      network_router = persister.network_routers.find_or_build(tier_1['id'])
      network_router.name = tier_1['display_name']
      network_router.cloud_tenant = cloud_tenant(tier_1['tags'])
      network_router.status = 'active'
    end
  end

  def cloud_networks
    collector.segments.each do |segment|
      cloud_network = persister.cloud_networks.find_or_build(segment['id'])
      cloud_network.name = segment['display_name']
      cloud_network.description = segment['description']
      cloud_network.cloud_tenant = cloud_tenant(segment['tags'])
      cloud_network.status = 'active'
      cloud_network.enabled = true
      cloud_network.extra_attributes = { :subnet_mask => get_tag_value_by_scope(segment['tags'], 'subnet_mask') }
      cloud_subnets(segment)
    end
  end

  def cloud_subnets(segment)
    return if segment['subnets'].nil?
    segment['subnets'].each do |segment_subnet|
      id = "#{segment['id']}-#{segment_subnet['gateway_address']}"
      network_router_id = segment['connectivity_path'].split('/infra/tier-1s/').last
      cloud_subnet = persister.cloud_subnets.find_or_build(id)
      cloud_subnet.name = "#{segment['display_name']}-#{segment_subnet['gateway_address']}"
      cloud_subnet.cloud_tenant = cloud_tenant(segment['tags'])
      cloud_subnet.cidr = segment_subnet['network']
      cloud_subnet.gateway = segment_subnet['gateway_address']
      cloud_subnet.dhcp_enabled = false
      cloud_subnet.cloud_network = persister.cloud_networks.lazy_find(segment['id'])
      cloud_subnet.network_router = persister.network_routers.lazy_find(network_router_id)

      # TODO: this depends on vm.instance_uuid which doesn't exist yet
      # network_ports(segment, cloud_subnet)
    end
  end

  def network_ports(segment, cloud_subnet)
    Lan.where(:ems_ref => segment['id']).each do |lan|
      lan.vms.each do |vm|
        return if cloud_subnet.cloud_tenant.nil?
        return if vm.tenant_id != cloud_subnet.cloud_tenant.source_tenant.id
        network_port = persister.network_ports.find_or_build(vm.instance_uuid)
        network_port.name = vm.name
        network_port.cloud_tenant = cloud_subnet.cloud_tenant
        network_port.cloud_subnets = [] if network_port.cloud_subnets.nil?
        network_port.cloud_subnets << cloud_subnet
        network_port.status = 'active'
        network_port.device = vm
      end
    end
  end

  def security_groups
    collector.groups.each do |group|
      next if group['id'] == 'ANY'
      security_group = persister.security_groups.find_or_build(group['id'])
      security_group.name = group['display_name']
      security_group.description = group['description']
      security_group.cloud_tenant = cloud_tenant(group['tags'])
      security_group.network_ports = []
      security_groups_network_ports(security_group)
    end
  end

  def security_groups_network_ports(security_group)
    group_members = collector.group_members(security_group.ems_ref)
    group_members.each do |group_member|
      # TODO: This depends on vm.instance_uuid which doesn't exist yet
      # vm = Vm.find_by(:instance_uuid => group_member['id'])
      # next if vm.nil?
      # network_port = persister.network_ports.find_or_build(group_member['id'])
      # network_port.name = group_member['display_name']
      # network_port.cloud_tenant = security_group.cloud_tenant
      # network_port.status = 'active'
      # network_port.device = vm
      # network_port.device_ref = group_member['id']
      # network_port.security_groups = [] if network_port.security_groups.nil?
      # network_port.security_groups << security_group
    end
  end

  def security_policies
    collector.security_policies.each do |policy|
      security_policy = persister.security_policies.find_or_build(policy['id'])
      security_policy.name = policy['display_name']
      security_policy.description = policy['description']
      security_policy.cloud_tenant = cloud_tenant(policy['tags'])
      security_policy.sequence_number = policy['sequence_number']
      security_policy_rules(security_policy)
    end
  end

  def security_policy_rules(security_policy)
    collector.security_policy_rules(security_policy.ems_ref).each do |rule|
      security_policy_rule = persister.security_policy_rules.find_or_build(rule['id'])
      security_policy_rule.name = rule['display_name']
      security_policy_rule.description = rule['description']
      security_policy_rule.cloud_tenant = security_policy.cloud_tenant
      security_policy_rule.security_policy = security_policy
      security_policy_rule.sequence_number = rule['sequence_number']
      security_policy_rule.status = !rule['disabled'] ? 'active' : 'disabled'
      security_policy_rule.action = rule['action']
      security_policy_rule.direction = rule['direction']
      security_policy_rule.ip_protocol = rule['ip_protocol']
      security_policy_rule.source_security_groups = [] if security_policy_rule.source_security_groups.nil?
      rule['source_groups'].each do |group|
        next if group == 'ANY'
        security_group = persister.security_groups.lazy_find(group.split('/groups/').last)
        security_policy_rule.source_security_groups << security_group unless security_group.nil?
      end
      security_policy_rule.destination_security_groups = [] if security_policy_rule.destination_security_groups.nil?
      rule['destination_groups'].each do |group|
        next if group == 'ANY'
        security_group = persister.security_groups.lazy_find(group.split('/groups/').last)
        security_policy_rule.destination_security_groups << security_group unless security_group.nil?
      end
      security_policy_rule.network_services = [] if security_policy_rule.network_services.nil?
      rule['services'].each do |service|
        next if service == 'ANY'
        network_service = persister.network_services.lazy_find(service.split('/infra/services/').last)
        security_policy_rule.network_services << network_service unless network_service.nil?
      end
    end
  end

  private

  def get_tag_value_by_scope(tags, scope)
    tag = tags&.find { |t| t['scope'].upcase == scope.upcase }
    return nil if tag.nil?
    return tag['tag']
  end

  def cloud_tenant(tags)
    cloud_tenant_tag = get_tag_value_by_scope(tags, 'tenant')
    return nil if cloud_tenant_tag.nil?

    cloud_tenant_id = cloud_tenant_tag.upcase
    cloud_tenant = persister.cloud_tenants.find_or_build(cloud_tenant_id)
    cloud_tenant.name = cloud_tenant_id
    cloud_tenant.source_tenant = Tenant.find_by_name(cloud_tenant_id)
    return cloud_tenant
  end
end
