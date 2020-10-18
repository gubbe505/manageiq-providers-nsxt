import { componentTypes, validatorTypes } from '@@ddf';

const subnet_mask_options = [
  {
    label: '/24 (<= 253 hosts)',
    value: '/24',
  },
  {
    label: '/25 (<= 125 hosts)',
    value: '/25',
  },
  {
    label: '/26 (<= 61 hosts)',
    value: '/26',
  },
  {
    label: '/27 (<= 29 hosts)',
    value: '/27',
  },
  {
    label: '/28 (<= 13 hosts)',
    value: '/28',
  },
  {
    label: '/29 (<= 5 hosts)',
    value: '/29',
  }
];

const loadProviders = () => API.get("/api/providers?collection_class=ManageIQ::Providers::Nsxt::NetworkManager&expand=resources&attributes=id,name").then(({ resources }) =>
  resources.map(({ id: value, name: label }) => ({ label, value }))
);

export default (edit) => {
  const schema = {
    fields: [
      {
        component: componentTypes.SELECT,
        id: 'ems_id',
        name: 'ems_id',
        label: __('Provider'),
        isRequired: true,
        loadOptions: loadProviders,
        validate: [{ type: validatorTypes.REQUIRED }],
        hideField: edit
      },
      {
        component: componentTypes.TEXT_FIELD,
        id: 'name',
        name: 'name',
        label: __('Name'),
        placeholder: __('Name of the Cloud Network'),
        isRequired: true,
        validate: [{
          type: validatorTypes.REQUIRED,
          message: __('Name is required'),
        }],
      },
      {
        component: componentTypes.TEXT_FIELD,
        id: 'description',
        name: 'description',
        label: __('Description'),
        placeholder: __('Description of the Cloud Network'),
      },
      {
        component: componentTypes.SELECT,
        id: 'subnet_mask',
        name: 'subnet_mask',
        label: __('CIDR Subnet Mask'),
        placeholder: __('CIDR Subnet Mask for the subnet of the Cloud Network'),
        isRequired: true,
        validate: [
          {
            type: validatorTypes.REQUIRED,
            message: __('CIDR Subnet Mask is required'),   
          },
        ],
        options: subnet_mask_options,
        hideField: edit
      }
    ]
  }
  return schema;
};
 