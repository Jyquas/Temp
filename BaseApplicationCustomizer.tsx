import { BaseApplicationCustomizer } from '@microsoft/sp-application-base';
import { SPFI, spfi, SPFx } from '@pnp/sp';
import * as React from 'react';
import * as ReactDOM from 'react-dom';

export default class YourApplicationCustomizer extends BaseApplicationCustomizer<{}> {
  private _currentHubSiteId: string | undefined;
  private _containerElement: HTMLDivElement;
  private _styleTag: HTMLStyleElement;

  protected onInit(): Promise<void> {
    this.context.application.navigatedEvent.add(this, this._onNavigated);
    this._renderComponent();
    return Promise.resolve();
  }

  private _onNavigated(): void {
    const newHubSiteId = this.context.pageContext.site.hubSiteId;

    if (this._currentHubSiteId !== newHubSiteId) {
      this._currentHubSiteId = newHubSiteId;
      this._renderComponent();
    }
  }

  private _renderComponent(): void {
    // Ensure the previous component is unmounted
    if (this._containerElement) {
      ReactDOM.unmountComponentAtNode(this._containerElement);
      this._containerElement.remove();
    }

    // Check for configuration here...
    const hasConfiguration = /* your logic to check if the site has configuration */;
    
    if (hasConfiguration) {
      // Apply styles
      if (!this._styleTag) {
        this._styleTag = document.createElement('style');
        this._styleTag.type = 'text/css';
        this._styleTag.innerHTML = /* your CSS styles here */;
        document.head.appendChild(this._styleTag);
      }
  
      // Render component
      this._containerElement = document.createElement('div');
      this.domElement.appendChild(this._containerElement);
  
      const sp = spfi(this.context.pageContext.web.absoluteUrl, SPFx(this.context));
      const element = React.createElement(YourReactComponent, { sp });
      ReactDOM.render(element, this._containerElement);
    } else {
      // Remove styles
      if (this._styleTag) {
        this._styleTag.remove();
        this._styleTag = null;
      }
    }
  }

  protected onDispose(): void {
    // Ensure the component is unmounted when the extension is disposed
    if (this._containerElement) {
      ReactDOM.unmountComponentAtNode(this._containerElement);
      this._containerElement.remove();
    }

    // Remove styles
    if (this._styleTag) {
      this._styleTag.remove();
      this._styleTag = null;
    }

    super.onDispose();
  }
}
