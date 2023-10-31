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
  loadConfiguration: (listTitle?: string, itemTitle?: string) => Promise<void>;
}

const ConfigurationContext = createContext<ConfigurationContextProps | undefined>(undefined);

interface ConfigurationProviderProps {
  children: ReactNode;
  sp: SPFI;
  defaultListTitle: string;
  defaultItemTitle: string;
}

/**
 * Provides configuration data to child components.
 * Fetches configuration from SharePoint hub sites and stores it in context.
 */
const ConfigurationProvider: React.FC<ConfigurationProviderProps> = ({ children, sp, defaultListTitle, defaultItemTitle }): ReactElement => {
  const [configuration, setConfiguration] = useState<Configuration | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<Error | null>(null);

  /**
   * Fetches configuration recursively from the current hub site or its parent.
   * @param listTitle - The title of the list containing the configuration.
   * @param itemTitle - The title of the configuration item.
   */
  const loadConfiguration = async (listTitle?: string, itemTitle?: string) => {
    setLoading(true);
    try {
      const webUrl = window.location.origin;
      const config = await fetchHubSiteConfiguration(sp, webUrl, listTitle || defaultListTitle, itemTitle || defaultItemTitle);
      setConfiguration(config);
    } catch (err) {
      setError(err as Error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadConfiguration(defaultListTitle, defaultItemTitle);
  }, [sp]);

  // ... (previous implementation of fetchHubSiteConfiguration and fetchConfigurationFromList)

  return (
    <ConfigurationContext.Provider value={{ configuration, loading, error, loadConfiguration }}>
      {children}
    </ConfigurationContext.Provider>
  );
};

/**
 * Custom hook to access configuration context.
 * @param listTitle - Optional list title to override default.
 * @param itemTitle - Optional item title to override default.
 * @returns Configuration context.
 */
export const useConfiguration = (listTitle?: string, itemTitle?: string): ConfigurationContextProps => {
  const context = useContext(ConfigurationContext);
  if (context === undefined) {
    throw new Error('useConfiguration must be used within a ConfigurationProvider');
  }

  useEffect(() => {
    context.loadConfiguration(listTitle, itemTitle);
  }, [listTitle, itemTitle]);

  return context;
};

export default ConfigurationProvider;
