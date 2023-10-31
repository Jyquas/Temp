import { useState, useEffect } from 'react';
import { SPFI } from "@pnp/sp/presets/all";
import "@pnp/sp/webs";
import "@pnp/sp/hubsites";
import "@pnp/sp/lists";
import "@pnp/sp/items";

export interface ConfigurationHookProps {
  sp: SPFI;
  listTitle?: string;
  itemTitle?: string;
}

interface Configuration {
  [key: string]: any;
}

export const useConfigurationData = ({ sp, listTitle = "ConfigurationList", itemTitle = "Title" }: ConfigurationHookProps) => {
  const [configuration, setConfiguration] = useState<Configuration | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    const loadConfiguration = async () => {
      setLoading(true);
      try {
        const webUrl = window.location.origin;
        const config = await fetchHubSiteConfiguration(sp, webUrl, listTitle, itemTitle);
        setConfiguration(config);
      } catch (err) {
        setError(err as Error);
      } finally {
        setLoading(false);
      }
    };

    loadConfiguration();
  }, [sp, listTitle, itemTitle]);

  const fetchHubSiteConfiguration = async (sp: SPFI, webUrl: string, listTitle: string, itemTitle: string): Promise<Configuration | null> => {
    try {
      const web = sp.web;
      const hubSiteData = await web.hubSiteData();
  
      if (hubSiteData.IsHubSite) {
        const config = await fetchConfigurationFromList(sp, webUrl, listTitle, itemTitle);
        if (config) return config;
      }
  
      if (hubSiteData.ParentHubSiteId) {
        const parentHubSite = await sp.hubSites.getById(hubSiteData.ParentHubSiteId)();
        const parentHubSiteUrl = parentHubSite.SiteUrl;
  
        return await fetchHubSiteConfiguration(sp, parentHubSiteUrl, listTitle, itemTitle);
      }
  
      return null;
    } catch (error) {
      console.error('Error fetching hub site configuration:', error);
      throw error;
    }
  };

  const fetchConfigurationFromList = async (sp: SPFI, webUrl: string, listTitle: string, itemTitle: string): Promise<Configuration | null> => {
    try {
      const web = sp.web(webUrl);
      const items = await web.lists.getByTitle(listTitle).items.filter(`Title eq '${itemTitle}'`).get();

      if (items.length > 0) {
        const configuration = { ...items[0] };
        delete configuration['Id'];
        delete configuration['Title'];
        return configuration;
      }

      return null;
    } catch (error) {
      console.error('Error fetching configuration from list:', error);
      return null;
    }
  };

  return { configuration, loading, error };
};
