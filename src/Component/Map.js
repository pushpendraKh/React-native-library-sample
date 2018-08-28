import React from 'react'
import MapView, {Marker} from 'react-native-maps'

const RenderMapView = ({onRegionChange, coordinate, initialRegion}) => {
    return(
      <MapView
          style = {{flex:1}}
          initialRegion={ initialRegion }
          onRegionChange = { onRegionChange }
       >
          <Marker
            draggable
            coordinate={coordinate}
            title='Acko'
            description='A Insurance company'
          />
       </MapView>
    )
  }

  export default RenderMapView