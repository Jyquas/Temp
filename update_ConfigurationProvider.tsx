import React, { createContext, useContext, useState, useEffect, ReactNode, ReactElement } from 'react';
import { SPFI, spfi, SPFx } from "@pnp/sp/presets/all";
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

interface ConfigurationProviderProps {
  children: ReactNode;
  sp: SPFI;
}

/**
 * Provides configuration data to child components.
 * Fetches configuration from SharePoint hub sites and stores it in context.
 */
const ConfigurationProvider: React.FC<ConfigurationProviderProps> = ({ children, sp }): ReactElement => {
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
        const config = await fetchHubSiteConfiguration(sp, webUrl);
        setConfiguration(config);
      } catch (err) {
        setError(err as Error);
      } finally {
        setLoading(false);
      }
    };

    loadConfiguration();
  }, [sp]);

  /**
   * Fetches configuration recursively from the current hub site or its parent.
   * @param sp - PnPjs SPFI object.
   * @param webUrl - The URL of the current web.
   * @returns Configuration object if found, or null.
   */
  const fetchHubSiteConfiguration = async (sp: SPFI, webUrl: string): Promise<Configuration | null> => {
    try {
      const web = sp.web;
      const hubSiteData = await web.hubSiteData();
  
      if (hubSiteData.IsHubSite) {
        const config = await fetchConfigurationFromList(sp, webUrl);
        if (config) return config;
      }
  
      if (hubSiteData.ParentHubSiteId) {
        const parentHubSiteId = hubSiteData.ParentHubSiteId;
        const parentHubSite = await sp.hubSites.getById(parentHubSiteId)();
        const parentHubSiteUrl = sp.web(parentHubSite.SiteId).toUrl();
  
        return await fetchHubSiteConfiguration(sp, parentHubSiteUrl);
      }
  
      return null;
    } catch (error) {
      console.error('Error fetching hub site configuration:', error);
      throw error;
    }
  };

  /**
   * Fetches configuration from a SharePoint list.
   * @param sp - PnPjs SPFI object.
   * @param webUrl - The URL of the web to fetch the configuration from.
   * @returns Configuration object if found, or null.
   */
  const fetchConfigurationFromList = async (sp: SPFI, webUrl: string): Promise<Configuration | null> => {
    try {
      const listTitle = 'ConfigurationList'; // Replace with your actual list title
      const itemId = 1; // Replace with the ID of your configuration item
      const web = sp.web(webUrl);
      const item = await web.lists.getByTitle(listTitle).items.getById(itemId).get();

      const configuration = { ...item };
      delete configuration['Id'];
      delete configuration['Title'];

      return configuration;
    } catch (error) {
      console.error('Error fetching configuration from list:', error);
      return null;
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
