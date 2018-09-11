import React from 'react';
import { Text, View, Animated } from 'react-native';
import { createBottomTabNavigator, createStackNavigator } from 'react-navigation';
import Icon from 'react-native-vector-icons/Ionicons';
import App from './App'
import MessageScreen from './MessageScreen'
import Animation from './Animation'
import LinkWebView from './LinkWebView'

class ProfileScreen extends React.Component {
    constructor(props) {
      super(props)
      this.state = {

      }
    }

    componentWillMount() {
      this.position = new Animated.ValueXY(0,0)

    }

    render() {
      return (
        <View style={ this.position.getLayout()}>
          <View style = {{ width: 100, height: 100, borderRadius: 50, backgroundColor: 'purple'}}/>
        </View>
      );
    }
  }

const WebStackView = createStackNavigator({
  Map: App,
  Web: {
    screen: LinkWebView,
    navigationOptions: {
      title: 'Linkedin',
    },
  }
})  

class TabNavigation extends React.Component {

  static navigationOptions = { header: null }

  render() {
    return <Navigator></Navigator>
  }

}

export default Navigator = createBottomTabNavigator({
    Map: WebStackView,
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
          iconName = `ios-person`
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

const MainNavigator = createStackNavigator({
  Main: {
    screen: TabNavigation,
    navigationOptions: { header: null }
  },
  // Tab: {
  //     screen: TabNavigation,
  //     navigationOptions: { header: null
  //         //title: 'WEB VIEW',
  //         // headerStyle: {
  //         //     backgroundColor: '#568EA4',
  //         // },
  //     },
  // },
  Web: LinkWebView

})