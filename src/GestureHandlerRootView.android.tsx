import * as React from 'react';
import { PropsWithChildren } from 'react';
import { requireNativeComponent, ViewProps } from 'react-native';
import { ENABLE_FABRIC } from './utils';

const GestureHandlerRootViewNativeComponent = ENABLE_FABRIC
  ? require('./fabric/RNGestureHandlerRootViewNativeComponent')
  : requireNativeComponent('RNGestureHandlerRootView');

export interface GestureHandlerRootViewProps
  extends PropsWithChildren<ViewProps> {}

export default function GestureHandlerRootView({
  children,
  ...rest
}: GestureHandlerRootViewProps) {
  return (
    <GestureHandlerRootViewNativeComponent {...rest}>
      {children}
    </GestureHandlerRootViewNativeComponent>
  );
}
