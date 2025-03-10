import { openJsInspector, queryAllInspectorAppsAsync } from '@expo/dev-server';
import assert from 'assert';
import chalk from 'chalk';

import * as Log from '../../log';
import { learnMore } from '../../utils/link';
import { selectAsync } from '../../utils/prompts';
import { DevServerManager } from '../server/DevServerManager';
import { BLT, printHelp, printItem, printQRCode, printUsage, StartOptions } from './commandsTable';

const debug = require('debug')('expo:start:interface:interactiveActions') as typeof console.log;

/** Wraps the DevServerManager and adds an interface for user actions. */
export class DevServerManagerActions {
  constructor(private devServerManager: DevServerManager) {}

  printDevServerInfo(
    options: Pick<StartOptions, 'devClient' | 'isWebSocketsEnabled' | 'platforms'>
  ) {
    // If native dev server is running, print its URL.
    if (this.devServerManager.getNativeDevServerPort()) {
      const devServer = this.devServerManager.getDefaultDevServer();
      try {
        const nativeRuntimeUrl = devServer.getNativeRuntimeUrl()!;
        const interstitialPageUrl = devServer.getRedirectUrl();

        printQRCode(interstitialPageUrl ?? nativeRuntimeUrl);

        if (interstitialPageUrl) {
          Log.log(
            printItem(
              chalk`Choose an app to open your project at {underline ${interstitialPageUrl}}`
            )
          );
        }
        Log.log(printItem(chalk`Metro waiting on {underline ${nativeRuntimeUrl}}`));
        // TODO: if development build, change this message!
        Log.log(printItem('Scan the QR code above with Expo Go (Android) or the Camera app (iOS)'));
      } catch (error) {
        // @ts-ignore: If there is no development build scheme, then skip the QR code.
        if (error.code !== 'NO_DEV_CLIENT_SCHEME') {
          throw error;
        } else {
          const serverUrl = devServer.getDevServerUrl();
          Log.log(printItem(chalk`Metro waiting on {underline ${serverUrl}}`));
          Log.log(printItem(`Linking is disabled because the client scheme cannot be resolved.`));
        }
      }
    }

    const webDevServer = this.devServerManager.getWebDevServer();
    const webUrl = webDevServer?.getDevServerUrl({ hostType: 'localhost' });
    if (webUrl) {
      Log.log();
      Log.log(printItem(chalk`Web is waiting on {underline ${webUrl}}`));
    }

    printUsage(options, { verbose: false });
    printHelp();
    Log.log();
  }

  async openJsInspectorAsync() {
    Log.log('Opening JavaScript inspector in the browser...');
    const port = this.devServerManager.getNativeDevServerPort();
    assert(port, 'Metro dev server is not running');
    const metroServerOrigin = `http://localhost:${port}`;
    const apps = await queryAllInspectorAppsAsync(metroServerOrigin);
    if (!apps.length) {
      Log.warn(
        `No compatible apps connected. This feature is only available for apps using the Hermes runtime. ${learnMore(
          'https://docs.expo.dev/guides/using-hermes/'
        )}`
      );
      return;
    }
    for (const app of apps) {
      openJsInspector(app);
    }
  }

  reloadApp() {
    Log.log(`${BLT} Reloading apps`);
    // Send reload requests over the dev servers
    this.devServerManager.broadcastMessage('reload');
  }

  async openMoreToolsAsync() {
    try {
      // Options match: Chrome > View > Developer
      const value = await selectAsync(chalk`Dev tools {dim (native only)}`, [
        { title: 'Inspect elements', value: 'toggleElementInspector' },
        { title: 'Toggle performance monitor', value: 'togglePerformanceMonitor' },
        { title: 'Toggle developer menu', value: 'toggleDevMenu' },
        { title: 'Reload app', value: 'reload' },
        // TODO: Maybe a "View Source" option to open code.
        // Toggling Remote JS Debugging is pretty rough, so leaving it disabled.
        // { title: 'Toggle Remote Debugging', value: 'toggleRemoteDebugging' },
      ]);
      this.devServerManager.broadcastMessage('sendDevCommand', { name: value });
    } catch (error: any) {
      debug(error);
      // do nothing
    } finally {
      printHelp();
    }
  }

  toggleDevMenu() {
    Log.log(`${BLT} Toggling dev menu`);
    this.devServerManager.broadcastMessage('devMenu');
  }
}
