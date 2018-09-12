/** @format */

import {AppRegistry} from 'react-native';
import MainNavigator from './src/Navigation/Navigation';
import {name as appName} from './app.json';

AppRegistry.registerComponent(appName, () => MainNavigator);
