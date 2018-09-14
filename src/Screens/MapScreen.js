/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 * @flow
 */

import React, {Component} from 'react';
import { StyleSheet, View, Text} from 'react-native';
import RenderMapView from '../Component/RenderMapView'
import firebase from 'react-native-firebase'
import { Button } from '../Component/Common/Button';

export default class MapScreen extends Component {

  static navigationOptions = {
    header: null
  }

  constructor(props) {
    super(props)
    this.state = {
      region: {
        latitude: 12.9030558,
        longitude: 77.5969069,
        latitudeDelta: 0.0922,
        longitudeDelta: 0.0421,
      },
      coordinate: {
        latitude: 12.9030558,
        longitude: 77.5969069
      },
    }
  }

  componentWillMount() {
    firebase.analytics().logEvent("home_screen_apprearing", {data: 'maps'})
    firebase.analytics().setCurrentScreen('Home_screen')
  }

  setMarkerPosition = (region) => {
    console.log(region);
    this.setState({
      region: region,
      coordinate: {
        latitude: region.latitude,
        longitude: region.longitude
      }
    })
  }

  render() {
    console.log(this.state.region);
    return (
      <View style={styles.container}>
      <RenderMapView 
          style = {{flex: 8}}
          onRegionChange = {this.setMarkerPosition}
          coordinate = { this.state.coordinate } 
          region = { this.state.region }
       />
       <Text>
         { "Latitude " + this.state.coordinate.latitude + " , " + "Longitude " + this.state.coordinate.longitude }
       </Text>  
       <Button
          style = {{flex: 1}}
          onPress = { () => {
            this.props.navigation.navigate('Web', {
              url: 'https://www.linkedin.com/in/pushpendra-khandelwal-3a818ba1/'
            })
          }}
         >
            Click me
       </Button>
    </View>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F5FCFF',
  },

  mapStyle: {
    flex: 1,
  },
});
