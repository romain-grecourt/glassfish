package org.glassfish.api.deployment;

import org.jvnet.hk2.annotations.Contract;

import java.io.IOException;

/**
 * Implementations of this interface are providing deployment application metadata
 *
 * @author Jerome Dochez
 */
@Contract
public interface ApplicationMetaDataProvider<T> extends MetaDataProvider {


    /**
     * Load the metadata associated with the deployment event
     * @param dc the deployment context
     * @return the loaded metadata
     * @throws IOException when the underlying archive cannot be processed correctly
     */
    T load(DeploymentContext dc, Object defaultValue) throws IOException;
}
