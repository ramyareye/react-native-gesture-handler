import {Animated, Text, View} from 'react-native';

import React from 'react';
import {
  PanGestureHandler,
  PanGestureHandlerStateChangeEvent,
  State,
} from 'react-native-gesture-handler';

type Props = {
  useNativeDriver: boolean;
  color: string;
};

export function OldAPIAnimatedEventExample({useNativeDriver, color}: Props) {
  const drag = React.useRef(new Animated.Value(0));
  const isPressed = React.useRef(new Animated.Value(0));
  const viewRef = React.useRef<View>();

  const onGestureEvent = Animated.event(
    [{nativeEvent: {translationX: drag.current}}],
    {useNativeDriver},
  );

  const onHandlerStateChange = (event: PanGestureHandlerStateChangeEvent) => {
    if (event.nativeEvent.state === State.BEGAN) {
      if (useNativeDriver) {
        // @ts-ignore: Fabric
        if (viewRef.current?._internalInstanceHandle) {
          // setNativeProps is not currently supported in Fabric
        } else {
          viewRef.current?.setNativeProps({backgroundColor: 'black'});
        }
      } else {
        isPressed.current.setValue(1);
      }
    } else if (
      event.nativeEvent.state === State.FAILED ||
      event.nativeEvent.state === State.CANCELLED ||
      event.nativeEvent.state === State.END
    ) {
      Animated.spring(drag.current, {
        velocity: event.nativeEvent.velocityX,
        tension: 10,
        friction: 2,
        toValue: 0,
        useNativeDriver,
      }).start();
      if (useNativeDriver) {
        // @ts-ignore: Fabric
        if (viewRef.current?._internalInstanceHandle) {
          // setNativeProps is not currently supported in Fabric
        } else {
          viewRef.current?.setNativeProps({backgroundColor: color});
        }
      } else {
        isPressed.current.setValue(0);
      }
    }
  };

  // Style property 'backgroundColor' is not supported by native animated module
  const backgroundColor = useNativeDriver
    ? color
    : isPressed.current.interpolate({
        inputRange: [0, 1],
        outputRange: [color, 'black'],
      });

  return (
    <View>
      <Text>
        Old API / Animated.event / useNativeDriver: {useNativeDriver.toString()}
      </Text>
      <View
        style={{height: 50, alignItems: 'center', justifyContent: 'center'}}
      >
        <PanGestureHandler
          maxPointers={1}
          onGestureEvent={onGestureEvent}
          onHandlerStateChange={onHandlerStateChange}
        >
          <Animated.View
            style={{
              width: 45,
              height: 45,
              backgroundColor,
              alignItems: 'center',
              justifyContent: 'center',
              transform: [{translateX: drag.current}],
            }}
            ref={viewRef}
          />
        </PanGestureHandler>
      </View>
    </View>
  );
}
