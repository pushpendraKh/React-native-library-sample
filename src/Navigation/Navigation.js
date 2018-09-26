import React from 'react';
import { createBottomTabNavigator, createStackNavigator } from 'react-navigation';
import Icon from 'react-native-vector-icons/Ionicons';
import MapScreen from '../Screens/MapScreen'
import MessageScreen from '../Screens/PhotoCaptureScreen'
import Animation from '../Screens/AnimationScreen'
import LinkWebView from '../Screens/WebViewScreen'
import ProfileScreen from '../Screens/ProfileScreen'

const TabNagivator = createBottomTabNavigator({
    Map: MapScreen,
    Upload: MessageScreen,
    Animation: Animation,
    Profile: ProfileScreen,
  },
  {
  navigationOptions: ({ navigation }) => ({
    tabBarIcon: ({ tintColor }) => {
      const { routeName } = navigation.state;
      let iconName;
      switch (routeName) {
        case 'Map':  
          iconName = `ios-map`
          break
        case 'Animation': 
          iconName = `ios-mail`
          break 
        case 'Upload': 
          iconName = `ios-share`
          break
        case 'Profile': 
          iconName = `ios-share`
          break
        default: 
      }
      return <Icon name={iconName} size={25} color={tintColor} />;
    },
  }),

  tabBarOptions: {
    activeTintColor: 'black',
    inactiveTintColor: 'gray',
  },
  })

const MainNavigation = createStackNavigator({
  Tab: {
    screen: TabNagivator,
    navigationOptions: { header: null }
  },
  Web: LinkWebView,
})

export default MainNavigation;