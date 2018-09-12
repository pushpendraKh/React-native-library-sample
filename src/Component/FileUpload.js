// Not used currently
import React, { Component } from 'react';

import {
  StyleSheet,
  Component,
  View,
  DeviceEventEmitter,
} from 'react-native';

var RNUploader = NativeModules.RNUploader;

export default class FileUpload extends Component {
    componentDidMount() {
        DeviceEventEmitter.addListener('RNUploaderProgress', (data)=>{
          let bytesWritten = data.totalBytesWritten;
          let bytesTotal   = data.totalBytesExpectedToWrite;
          let progress     = data.progress;
          
          console.log( "upload progress: " + progress + "%");
        });
    }

    render() {
        
    }
}