import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { WebPartContext } from "@microsoft/sp-webpart-base";
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

interface ConfigurationProviderProps {
  children: ReactNode;
  spfxContext: WebPartContext;
}

const ConfigurationProvider: React.FC<ConfigurationProviderProps> = ({ children, spfxContext }) => {
  const [configuration, setConfiguration] = useState<Configuration | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    const loadConfiguration = async () => {
      setLoading(true);
      try {
        const sp = spfi().using(SPFx(spfxContext));
        const webUrl = spfxContext.pageContext.web.absoluteUrl;
        const config = await fetchHubSiteConfiguration(sp, webUrl);
        setConfiguration(config);
      } catch (err) {
        if (err instanceof Error) {
          setError(err);
        } else {
          setError(new Error('Unknown error occurred'));
        }
      } finally {
        setLoading(false);
      }
    };

    loadConfiguration();
  }, [spfxContext]);

  const fetchHubSiteConfiguration = async (sp, webUrl: string): Promise<Configuration | null> => {
    try {
      const web = sp.web(webUrl);
      const hubSiteData = await web.hubSiteData();
  
      if (hubSiteData.IsHubSite) {
        const config = await fetchConfigurationFromList(sp, webUrl);
        if (config) return config;
      }
  
      if (hubSiteData.ParentHubSiteId) {
        const parentHubSiteId = hubSiteData.ParentHubSiteId;
        const parentHubSiteProperties = await sp.hubSites.getById(parentHubSiteId)();
        const parentHubSiteUrl = parentHubSiteProperties.SiteUrl;
  
        return await fetchHubSiteConfiguration(sp, parentHubSiteUrl);
      }
  
      return null;
    } catch (error) {
      console.error('Error fetching hub site configuration:', error);
      throw error;
    }
  };

  const fetchConfigurationFromList = async (sp, webUrl: string): Promise<Configuration | null> => {
    try {
      const listTitle = 'ConfigurationList';
      const itemId = 1;
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

export const useConfiguration = (): ConfigurationContextProps => {
  const context = useContext(ConfigurationContext);
  if (context === undefined) {
    throw new Error('useConfiguration must be used within a ConfigurationProvider');
  }
  return context;
};

export default ConfigurationProvider;
