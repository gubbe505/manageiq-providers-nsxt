import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import MiqFormRenderer from '@@ddf';
import createSchema from './nsxt-cloud-network-form.schema';

const NsxtCloudNetworkForm = ({ recordId }) => {
  const [{ isLoading, initialValues }, setState] = useState({
    isLoading: !!recordId,
    initialValues: {},  
  });

  useEffect(() => {
    if (!!recordId && ManageIQ.controller === 'cloud_network') {
      API.get(`/api/cloud_networks/${recordId}?attributes=name,description`).then(({ id, providerId, ...initialValues }) => {
        delete initialValues.href;
        setState({
          isLoading: false,
          initialValues,
        });
      });
    }
    if (!!recordId &&  ManageIQ.controller === 'ems_network') {
      initialValues.ems_id = recordId;
      setState({
        isLoading: false,
        initialValues,
      });
    }
  }, [recordId]);

  const initialize = (formOptions) => {
    ManageIQ.redux.store.dispatch({
      type: 'FormButtons.init',
      payload: {
        newRecord: true,
        pristine: true,
      },
    });

    ManageIQ.redux.store.dispatch({
      type: 'FormButtons.callbacks',
      payload: { addClicked: () => formOptions.submit() },
    });
  };

  const onSubmit = (values) => {
    miqSparkleOn();
    const request = !!recordId && ManageIQ.controller === 'cloud_network' ? 
      API.post(`/api/providers/${values.ems_id}/cloud_networks`, {
        action: 'edit',
        id: values.id,
        resource: { ...values },
      }) : 
      API.post(`/api/providers/${values.ems_id}/cloud_networks`, {
        action: 'create',
        resource: values,
      });
    request.then(miqSparkleOff);
  };

  return !isLoading && (
    <MiqFormRenderer
      schema={createSchema(!!recordId && ManageIQ.controller === 'cloud_network')}
      onSubmit={onSubmit}
      showFormControls={false}
      initialValues={initialValues}
      initialize={initialize}
    />
  );
};

NsxtCloudNetworkForm.propTypes = {
  recordId: PropTypes.string
};

NsxtCloudNetworkForm.defaultProps = {
  recordId: undefined
};

export default NsxtCloudNetworkForm;
