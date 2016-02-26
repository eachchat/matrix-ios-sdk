/*
 Copyright 2016 OpenMarket Ltd

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import <XCTest/XCTest.h>

#import "MatrixSDKTestsData.h"

#import "MXSession.h"

@interface MXEventTimelineTests : XCTestCase
{
    MatrixSDKTestsData *matrixSDKTestsData;

    MXSession *mxSession;
}
@end

@implementation MXEventTimelineTests

- (void)setUp
{
    [super setUp];

    matrixSDKTestsData = [[MatrixSDKTestsData alloc] init];
}

- (void)tearDown
{
    if (mxSession)
    {
        [matrixSDKTestsData closeMXSession:mxSession];
        mxSession = nil;
        matrixSDKTestsData = nil;
    }
    [super tearDown];
}

- (void)testPaginateOnContextTimeline
{
    [matrixSDKTestsData doMXSessionTestWithBobAndARoomWithMessages:self readyToTest:^(MXSession *mxSession2, MXRoom *room, XCTestExpectation *expectation) {
        mxSession = mxSession2;

        // Add 20 messages to the room
        [matrixSDKTestsData for:mxSession.matrixRestClient andRoom:room.roomId sendMessages:20 success:^{

            [room sendTextMessage:@"The initial timelime event" success:^(NSString *eventId) {

                // Add 20 more messages
                [matrixSDKTestsData for:mxSession.matrixRestClient andRoom:room.roomId sendMessages:20 success:^{

                    [room openTimelineOnEvent:eventId withLimit:10 success:^(MXEventTimeline *eventTimeline) {

                        [eventTimeline listenToEventsOfTypes:@[kMXEventTypeStringRoomMessage] onEvent:^(MXEvent *event, MXTimelineDirection direction, MXRoomState *roomState) {

                            NSLog(@"### %@", event);

                        }];

                        [eventTimeline resetPagination];
                        [eventTimeline paginate:1 direction:MXTimelineDirectionBackwards onlyFromStore:NO complete:^{


                            [expectation fulfill];

                        } failure:^(NSError *error) {
                            XCTFail(@"The operation should not fail - NSError: %@", error);
                            [expectation fulfill];
                        }];

                    } failure:^(NSError *error) {
                        XCTFail(@"The operation should not fail - NSError: %@", error);
                        [expectation fulfill];
                    }];

                }];
                
            } failure:^(NSError *error) {
                NSAssert(NO, @"Cannot set up intial test conditions - error: %@", error);
            }];

        }];

    }];
}


@end
