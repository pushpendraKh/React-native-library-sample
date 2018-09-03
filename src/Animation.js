
import React, {Component} from 'react';
import { StyleSheet, View, ScrollView, Image, Text, Animated} from 'react-native';
import firebase from 'react-native-firebase'

HEADER_MAX_HEIGHT = 120
HEADER_MIN_HEIGHT = 70
PROFILE_MAX_HEIGHT = 80
PROFILE_MIN_HEIGHT = 40

export default class Animation extends Component {

    constructor(props) {
        super(props)
        this.state = {
            scrollY: new Animated.Value(0)
        }
    }

    componentWillMount() {
        firebase.analytics().setCurrentScreen('Animation Screen');
        firebase.analytics().setUserProperty('userType','developer')
      }

      componentDidMount() {
        firebase.analytics().logEvent("animation_screen_appeared")
      }

    render() {

    const headerHeight = this.state.scrollY.interpolate({
        inputRange: [0, HEADER_MAX_HEIGHT - HEADER_MIN_HEIGHT],
        outputRange: [HEADER_MAX_HEIGHT, HEADER_MIN_HEIGHT],
        extrapolate: 'clamp'
    })

    const profileImageHeight = this.state.scrollY.interpolate({
        inputRange: [0, HEADER_MAX_HEIGHT - HEADER_MIN_HEIGHT],
        outputRange: [PROFILE_MAX_HEIGHT, PROFILE_MIN_HEIGHT],
        extrapolate: 'clamp'
    })

    const profileImageMarginTop = this.state.scrollY.interpolate({
        inputRange: [0, HEADER_MAX_HEIGHT - HEADER_MIN_HEIGHT],
        outputRange: [HEADER_MAX_HEIGHT - (PROFILE_MAX_HEIGHT) / 2, HEADER_MAX_HEIGHT],
        extrapolate: 'clamp'
    })

    const headerZindex = this.state.scrollY.interpolate({
        inputRange: [0, HEADER_MAX_HEIGHT - HEADER_MIN_HEIGHT],
        outputRange: [0,1],
        extrapolate: 'clamp'
    })

    const headerTitleBottom = this.state.scrollY.interpolate({
        inputRange: [0, HEADER_MAX_HEIGHT - HEADER_MIN_HEIGHT,
             HEADER_MAX_HEIGHT - HEADER_MIN_HEIGHT + PROFILE_MIN_HEIGHT, 
             HEADER_MAX_HEIGHT - HEADER_MIN_HEIGHT + PROFILE_MIN_HEIGHT + 15],
        outputRange: [-20,-20, -20, 0],
        extrapolate: 'clamp'
    })

     const { 
            container, 
            headerStyle,
            imageViewStyle,
            imageStyle,
            textStyle
         } = styles
      return (
        <View style={container}>
          <Animated.View style = {{...headerStyle, 
            height: headerHeight,
            zIndex: headerZindex,
            alignItems: 'center',
            }}>

            <Animated.View 
                style = {{
                    position: 'absolute',
                    bottom: headerTitleBottom,
                }}
            >
                <Text style = {{
                    fontSize: 14,
                    fontWeight: 'bold',
                    color: 'white',
                }}>
                    Pushpendra Khandelwal
                 </Text>   
            </Animated.View>    
           </Animated.View>

           <ScrollView 
                style = {container}
                scrollEventThrottle = {16}
                onScroll = { Animated.event(
                    [{nativeEvent: {
                        contentOffset: { y: this.state.scrollY}
                    }}]
                )}
           >
                <Animated.View style = {{...imageViewStyle, 
                    height: profileImageHeight,
                    width: profileImageHeight,
                    marginTop: profileImageMarginTop,
                    }} >
                    <Image 
                    style = {imageStyle}
                    source = {{uri: 'https://cloud.netlifyusercontent.com/assets/344dbf88-fdf9-42bb-adb4-46f01eedd629/242ce817-97a3-48fe-9acd-b1bf97930b01/09-posterization-opt.jpg'}}
                    />
                </Animated.View>
                <Text style = { textStyle}>
                    Pushpendra Khandelwal
                </Text>  
                <View style = {{height: 2000}}/>      
           </ScrollView>  
        </View>
      );
    }
  }

const styles = StyleSheet.create({
    container: {
        flex: 1,
    },
    headerStyle: {
        position: 'absolute',
        top: 0,
        left: 0,
        right: 0,
        backgroundColor: 'lightskyblue',
    },

    imageViewStyle: {
        height: PROFILE_MAX_HEIGHT,
        width: PROFILE_MAX_HEIGHT,
        borderRadius: PROFILE_MAX_HEIGHT/2,
        borderColor: 'white',  
        overflow: 'hidden',
        borderWidth: 3,   
        marginTop: HEADER_MAX_HEIGHT - (PROFILE_MAX_HEIGHT) / 2,
        marginLeft: 10,   
    },

    imageStyle: {
        flex: 1,
        width: null,
        height: null,
    },

    textStyle: {
        fontWeight: 'bold',
        fontSize: 15,
        paddingLeft: 10,
    },
})