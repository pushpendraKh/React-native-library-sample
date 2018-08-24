import React from 'react'
import MapView, {Marker} from 'react-native-maps'

const RenderMapView = () => {
    return(
      <MapView
          style = {{flex:1}}
          initialRegion={{
            latitude: 37.78825,
            longitude: -122.4324,
            latitudeDelta: 0.0922,
            longitudeDelta: 0.0421,
           }}
       >
          <Marker
            coordinate={{
              latitude: 37.78825,
              longitude: -122.4324
            }}
            title='Acko'
            description='A Insurance company'
          />
       </MapView>
    )
  }

  export default RenderMapView