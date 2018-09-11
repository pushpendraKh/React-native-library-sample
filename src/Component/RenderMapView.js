import React from 'react'
import MapView, {Marker} from 'react-native-maps'

const RenderMapView = ({style, onRegionChange, coordinate, initialRegion, }) => {
    return(
      <MapView
          style = {style}
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