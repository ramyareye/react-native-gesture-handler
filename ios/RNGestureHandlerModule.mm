#import "RNGestureHandlerModule.h"

#import <React/RCTLog.h>
#import <React/RCTViewManager.h>
#import <React/RCTComponent.h>
#import <React/RCTUIManager.h>
#import <React/RCTUIManagerUtils.h>
#import <React/RCTUIManagerObserverCoordinator.h>

#ifdef RN_FABRIC_ENABLED
#import <React/RCTBridge.h>
#import <ReactCommon/RCTTurboModule.h>
#import <React/RCTBridge+Private.h>
#import <ReactCommon/CallInvoker.h>
#import <React/RCTUtils.h>

#import <react/renderer/uimanager/primitives.h>
#endif // RN_FABRIC_ENABLED

#import "RNGestureHandlerState.h"
#import "RNGestureHandlerDirection.h"
#import "RNGestureHandler.h"
#import "RNGestureHandlerManager.h"

#import "RNGestureHandlerButton.h"
#import "RNGestureHandlerStateManager.h"

@interface RNGestureHandlerModule () <RCTUIManagerObserver, RNGestureHandlerStateManager>

@end

typedef void (^GestureHandlerOperation)(RNGestureHandlerManager *manager);

@implementation RNGestureHandlerModule
{
    RNGestureHandlerManager *_manager;

    // Oparations called after views have been updated.
    NSMutableArray<GestureHandlerOperation> *_operations;
}

RCT_EXPORT_MODULE()

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

- (void)invalidate
{
    _manager = nil;
    [self.bridge.uiManager.observerCoordinator removeObserver:self];
}

- (dispatch_queue_t)methodQueue
{
    // This module needs to be on the same queue as the UIManager to avoid
    // having to lock `_operations` and `_preOperations` since `uiManagerWillFlushUIBlocks`
    // will be called from that queue.

    // This is required as this module rely on having all the view nodes created before
    // gesture handlers can be associated with them
    return RCTGetUIManagerQueue();
}

#ifdef RN_FABRIC_ENABLED
static void decorateRuntime(jsi::Runtime* jsiRuntime)
{
    auto& runtime = *jsiRuntime;
    auto isFormsStackingContext = jsi::Function::createFromHostFunction(
            runtime,
            jsi::PropNameID::forAscii(runtime, "isFormsStackingContext"),
            1,
            [](jsi::Runtime &runtime,
               const jsi::Value &thisValue,
               const jsi::Value *arguments,
               size_t count) -> jsi::Value
            {
                if (!arguments[0].isObject()) {
                    return jsi::Value::null();
                }

                auto shadowNode = arguments[0].asObject(runtime).getHostObject<facebook::react::ShadowNodeWrapper>(runtime)->shadowNode;
                bool isFormsStackingContext = shadowNode->getTraits().check(facebook::react::ShadowNodeTraits::FormsStackingContext);

                return jsi::Value(isFormsStackingContext);
            });
    runtime.global().setProperty(runtime, "isFormsStackingContext", std::move(isFormsStackingContext));
}
#endif // RN_FABRIC_ENABLED

- (void)setBridge:(RCTBridge *)bridge
{
    [super setBridge:bridge];

    _manager = [[RNGestureHandlerManager alloc]
                initWithUIManager:bridge.uiManager
                eventDispatcher:bridge.eventDispatcher];
    _operations = [NSMutableArray new];
    [bridge.uiManager.observerCoordinator addObserver:self];
}

#ifdef RN_FABRIC_ENABLED
RCT_EXPORT_BLOCKING_SYNCHRONOUS_METHOD(install) {
    RCTCxxBridge *cxxBridge = (RCTCxxBridge *)self.bridge;
    decorateRuntime((jsi::Runtime *)cxxBridge.runtime);
    
    return @true;
}
#endif // RN_FABRIC_ENABLED

RCT_EXPORT_METHOD(createGestureHandler:(nonnull NSString *)handlerName tag:(nonnull NSNumber *)handlerTag config:(NSDictionary *)config)
{
    [self addOperationBlock:^(RNGestureHandlerManager *manager) {
        [manager createGestureHandler:handlerName tag:handlerTag config:config];
    }];
}

RCT_EXPORT_METHOD(attachGestureHandler:(nonnull NSNumber *)handlerTag toViewWithTag:(nonnull NSNumber *)viewTag actionType: (nonnull NSNumber *)actionType)
{
    [self addOperationBlock:^(RNGestureHandlerManager *manager) {
        [manager attachGestureHandler:handlerTag toViewWithTag:viewTag withActionType:actionType];
    }];
}

RCT_EXPORT_METHOD(updateGestureHandler:(nonnull NSNumber *)handlerTag config:(NSDictionary *)config)
{
    [self addOperationBlock:^(RNGestureHandlerManager *manager) {
        [manager updateGestureHandler:handlerTag config:config];
    }];
}

RCT_EXPORT_METHOD(dropGestureHandler:(nonnull NSNumber *)handlerTag)
{
    [self addOperationBlock:^(RNGestureHandlerManager *manager) {
        [manager dropGestureHandler:handlerTag];
    }];
}

RCT_EXPORT_METHOD(handleSetJSResponder:(nonnull NSNumber *)viewTag blockNativeResponder:(nonnull NSNumber *)blockNativeResponder)
{
    [self addOperationBlock:^(RNGestureHandlerManager *manager) {
        [manager handleSetJSResponder:viewTag blockNativeResponder:blockNativeResponder];
    }];
}

RCT_EXPORT_METHOD(handleClearJSResponder)
{
    [self addOperationBlock:^(RNGestureHandlerManager *manager) {
        [manager handleClearJSResponder];
    }];
}

- (void)setGestureState:(int)state forHandler:(int)handlerTag
{
  RNGestureHandler *handler = [_manager handlerWithTag:@(handlerTag)];

  if (handler != nil) {
    if (state == 1) { // FAILED
      handler.recognizer.state = UIGestureRecognizerStateFailed;
    } else if (state == 2) { // BEGAN
      handler.recognizer.state = UIGestureRecognizerStatePossible;
    } else if (state == 3) { // CANCELLED
      handler.recognizer.state = UIGestureRecognizerStateCancelled;
    } else if (state == 4) { // ACTIVE
      [handler stopActivationBlocker];
      handler.recognizer.state = UIGestureRecognizerStateBegan;
    } else if (state == 5) { // ENDED
      handler.recognizer.state = UIGestureRecognizerStateEnded;
    }
  }
  
  // if the gesture was set to finish, cancel all pointers it was tracking
  if (state == 1 || state == 3 || state == 5) {
    [handler.pointerTracker cancelPointers];
  }
  
  // do not send state change event when activating because it bypasses
  // shouldRequireFailureOfGestureRecognizer
  if (state != 4) {
    [handler handleGesture:handler.recognizer];
  }
}

#pragma mark -- Batch handling

- (void)addOperationBlock:(GestureHandlerOperation)operation
{
    [_operations addObject:operation];
}

#pragma mark - RCTUIManagerObserver

- (void)uiManagerWillFlushUIBlocks:(RCTUIManager *)uiManager
{
  [self uiManagerWillPerformMounting:uiManager];
}

- (void)uiManagerWillPerformMounting:(RCTUIManager *)uiManager
{
    if (_operations.count == 0) {
        return;
    }

    NSArray<GestureHandlerOperation> *operations = _operations;
    _operations = [NSMutableArray new];

    [uiManager addUIBlock:^(__unused RCTUIManager *manager, __unused NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        for (GestureHandlerOperation operation in operations) {
            operation(self->_manager);
        }
    }];
}

#pragma mark Events

- (NSArray<NSString *> *)supportedEvents
{
    return @[@"onGestureHandlerEvent", @"onGestureHandlerStateChange"];
}

#pragma mark Module Constants

- (NSDictionary *)constantsToExport
{
    return @{ @"State": @{
                      @"UNDETERMINED": @(RNGestureHandlerStateUndetermined),
                      @"BEGAN": @(RNGestureHandlerStateBegan),
                      @"ACTIVE": @(RNGestureHandlerStateActive),
                      @"CANCELLED": @(RNGestureHandlerStateCancelled),
                      @"FAILED": @(RNGestureHandlerStateFailed),
                      @"END": @(RNGestureHandlerStateEnd)
                      },
              @"Direction": @{
                      @"RIGHT": @(RNGestureHandlerDirectionRight),
                      @"LEFT": @(RNGestureHandlerDirectionLeft),
                      @"UP": @(RNGestureHandlerDirectionUp),
                      @"DOWN": @(RNGestureHandlerDirectionDown)
                      }
              };
}



@end
