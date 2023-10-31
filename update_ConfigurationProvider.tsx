import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { spfi, SPFx } from "@pnp/sp/presets/all";
import "@pnp/sp/webs";
import "@pnp/sp/hubsites";
import "@pnp/sp/lists";
import "@pnp/sp/items";

interface Configuration {
  [key: string]: any;
}

interface ConfigurationContextProps {
  configuration: Configuration | null;
  loading: boolean;
  error: Error | null;
}

const ConfigurationContext = createContext<ConfigurationContextProps | undefined>(undefined);

/**
 * Initializes PnPjs with SharePoint Framework context
 */
const sp = spfi().using(SPFx({ pageContext: window._spPageContextInfo }));

interface ConfigurationProviderProps {
  children: ReactNode;
}

/**
 * Provides configuration data to child components.
 * Fetches configuration from SharePoint hub sites and stores it in context.
 */
const ConfigurationProvider: React.FC<ConfigurationProviderProps> = ({ children }) => {
  const [configuration, setConfiguration] = useState<Configuration | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    /**
     * Fetches configuration from hub sites.
     */
    const loadConfiguration = async () => {
      setLoading(true);
      try {
        const webUrl = window.location.origin;
        const config = await fetchHubSiteConfiguration(webUrl);
        setConfiguration(config);
      } catch (err) {
        setError(err instanceof Error ? err : new Error('Unknown error occurred'));
      } finally {
        setLoading(false);
      }
    };

    loadConfiguration();
  }, []);

  const fetchHubSiteConfiguration = async (webUrl: string): Promise<Configuration | null> => {
    try {
      const web = sp.web(webUrl);
      const hubSiteData = await web.hubSiteData();
  
      if (hubSiteData.IsHubSite) {
        const config = await fetchConfigurationFromList(webUrl);
        if (config) return config;
      }
  
      if (hubSiteData.ParentHubSiteId) {
        const parentHubSiteId = hubSiteData.ParentHubSiteId;
        const parentHubSiteProperties = await sp.hubSites.getById(parentHubSiteId)();
        const parentHubSiteUrl = parentHubSiteProperties.SiteUrl;
  
        return await fetchHubSiteConfiguration(parentHubSiteUrl);
      }
  
      return null;
    } catch (error) {
      console.error('Error fetching hub site configuration:', error);
      throw error;
    }
  };

  const fetchConfigurationFromList = async (webUrl: string): Promise<Configuration | null> => {
    try {
      const listTitle = 'ConfigurationList'; // Replace with your actual list title
      const itemId = 1; // Replace with the ID of your configuration item
      const web = sp.web(webUrl);
      const item = await web.lists.getByTitle(listTitle).items.getById(itemId).get();

      const configuration: Configuration = { ...item };
      delete configuration['Id']; // Remove properties you don't need in the configuration
      delete configuration['Title'];

      return configuration;
    } catch (error) {
      console.error('Error fetching configuration from list:', error);
      return null; // Return null if configuration not found or error occurred
    }
  };

  return (
    <ConfigurationContext.Provider value={{ configuration, loading, error }}>
      {children}
    </ConfigurationContext.Provider>
  );
};

/**
 * Custom hook to access configuration context.
 * @returns Configuration context.
 */
export const useConfiguration = (): ConfigurationContextProps => {
  const context = useContext(ConfigurationContext);
  if (context === undefined) {
    throw new Error('useConfiguration must be used within a ConfigurationProvider');
  }
  return context;
};

export default ConfigurationProvider;
