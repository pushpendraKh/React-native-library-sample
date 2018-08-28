/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 * @flow
 */

import React, {Component} from 'react';
import { StyleSheet, View} from 'react-native';
import MapView from 'react-native-maps'
import RenderMapView from '../src/Component/Map'

export default class App extends Component {

  constructor(props) {
    super(props)
    this.state = {
      region: {
        latitude: 37.78825,
        longitude: -122.4324,
        latitudeDelta: 0.0922,
        longitudeDelta: 0.0421,
      },
      coordinate: {
        latitude: 37.78825,
        longitude: -122.4324
      },
    }
  }

  setMarkerPosition(region) {
    this.setState({
      coordinate: {
        latitude: region.latitude,
        longitude: region.longitude
      }
    })
  }

  render() {
    return (
      <View style={styles.container}>
        <RenderMapView 
            onRegionChange = { (region) => this.setMarkerPosition(region)}
            coordinate = { this.state.coordinate } 
            initialRegion = { this.state.initialRegion }
         />
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
