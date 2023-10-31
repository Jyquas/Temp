import React, { createContext, useContext, useState, useEffect, ReactNode, ReactElement } from 'react';
import { SPFI, spfi, SPFx } from "@pnp/sp/presets/all";
import "@pnp/sp/webs";
import "@pnp/sp/hubsites";
import "@pnp/sp/lists";
import "@pnp/sp/items";
import { Caching } from "@pnp/sp/cache";

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

const ConfigurationProvider: React.FC<ConfigurationProviderProps> = ({ children, sp }): ReactElement => {
  const [configuration, setConfiguration] = useState<Configuration | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
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

  const fetchConfigurationFromList = async (sp: SPFI, webUrl: string): Promise<Configuration | null> => {
    try {
      const listTitle = 'ConfigurationList';
      const itemId = 1;
      const web = sp.web(webUrl);
      const item = await web.lists.getByTitle(listTitle).items.getById(itemId).using(Caching({ storeName: "session" })).get();

      const configuration = { ...item };
      delete configuration['Id'];
      delete configuration['Title'];

      return configuration;
    } catch (error) {
      console.error('Error fetching configuration from list:', error);
      return null;
    }
  };

  const fetchHubSiteConfiguration = async (sp: SPFI, webUrl: string): Promise<Configuration | null> => {
    try {
      const web = sp.web(webUrl);
      const hubSiteData = await web.hubSiteData().using(Caching({ storeName: "session" }));

      const config = await fetchConfigurationFromList(sp, webUrl);
      if (config) return config;

      if (hubSiteData.IsHubSite && hubSiteData.ParentHubSiteId) {
        const parentHubSite = await sp.hubSites.getById(hubSiteData.ParentHubSiteId)();
        const parentHubSiteUrl = sp.web(parentHubSite.SiteId).toUrl();
        return await fetchHubSiteConfiguration(sp, parentHubSiteUrl);
      }

      return null;
    } catch (error) {
      console.error('Error fetching hub site configuration:', error);
      throw error;
    }
  };

  return (
    <ConfigurationContext.Provider value={{ configuration, loading, error }}>
      {children}
    </ConfigurationContext.Provider>
  );
};

export const useConfiguration = (): ConfigurationContextProps => {
  const context = useContext(ConfigurationContext);
  if (context === undefined) {
    throw new Error('useConfiguration must be used within a ConfigurationProvider');
  }
  return context;
};

export default ConfigurationProvider;
