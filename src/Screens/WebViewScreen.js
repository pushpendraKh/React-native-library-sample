import React, { Component } from 'react';
import {
  WebView,
} from 'react-native';

export default class WebViewScreen extends Component {

  componentWillMount() {
    console.log("Link");
    
  }

  render() {
    const url = this.props.navigation.getParam('url');
    return(
      <WebView
        source={{ uri: url }}
        startInLoadingState
      />
    )
  }
}