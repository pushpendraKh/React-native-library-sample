import React from 'react';
import { Text, View, Animated } from 'react-native';
import { createBottomTabNavigator, createStackNavigator } from 'react-navigation';
import Icon from 'react-native-vector-icons/Ionicons';
import App from './App'
import UploadPhoto from './Component/PhotoUpload';
import { Spinner} from './Component/Common'
import Animation from './Animation'
import firebase from 'react-native-firebase'

class MessageScreen extends React.Component {

  state = {
    isLoading: false,
    imageUri: 'https://www.sparklabs.com/forum/styles/comboot/theme/images/default_avatar.jpg'
  }

  
  componentWillMount() {
    firebase.analytics().setCurrentScreen('photoUpload');
  }

  componentDidMount() {
    firebase.analytics().logEvent("photo_upload_screen_appeared")
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
  
export default Navigator = createBottomTabNavigator({
    Map: App,
    Message: MessageScreen,
    Share: Animation,
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


