import React from 'react';
import { Text, View } from 'react-native';
import { createBottomTabNavigator, createStackNavigator } from 'react-navigation';
import Icon from 'react-native-vector-icons/Ionicons';
import App from './App'
import UploadPhoto from './Component/PhotoUpload';
import { Spinner} from './Component/Common'


class MessageScreen extends React.Component {

  state = {
    isLoading: false,
    imageUri: 'https://www.sparklabs.com/forum/styles/comboot/theme/images/default_avatar.jpg'
  }

  shouldStartLoading(flag) {
    this.setState({
      isLoading: flag
    })
  }

  didGetResponse(response) {
    this.setState({
      isLoading: false,
      imageUri: response.uri
    })
  }

  renderPhotoCapture() {
    if (this.state.isLoading) {
      return <Spinner/>
    } else {
      return(
        <UploadPhoto
        onStart = { () => {
          this.shouldStartLoading(true)
        }}
        onResponse = { (response) => {
          this.didGetResponse(response)
        }}
        imageUri = { this.state.imageUri }
        />
      )
    }
  }

  render() {
    return (
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
          { this.renderPhotoCapture() }
      </View>
    )
  }
}

class ShareScreen extends React.Component {
  render() {
    return (
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
        <Text>Share Screen!</Text>
      </View>
    );
  }
}

class ProfileScreen extends React.Component {
    render() {
      return (
        <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
          <Text>Profile Screen!</Text>
        </View>
      );
    }
  }
  
export default Navigator = createBottomTabNavigator({
    Map: App,
    Message: MessageScreen,
    Share: ShareScreen,
    Profile: ProfileScreen,
},
{
  navigationOptions: ({ navigation }) => ({
    tabBarIcon: ({ focused, tintColor }) => {
      const { routeName } = navigation.state;
      let iconName;
      switch (routeName) {
        case 'Map':  
           iconName = `ios-map`//focused ? `ios-home` : `home-outline`
           break
        case 'Message': 
          iconName = `ios-mail`
          break 
        case 'Share': 
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
}
)

