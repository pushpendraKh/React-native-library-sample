import React from 'react'
import { View, Animated } from 'react-native'

export default class ProfileScreen extends React.Component {
    constructor(props) {
      super(props)
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