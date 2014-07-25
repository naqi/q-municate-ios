//
//  QMFriendsListDataSource.m
//  Q-municate
//
//  Created by Andrey Ivanov on 4/3/14.
//  Copyright (c) 2014 Quickblox. All rights reserved.
//

#import "QMFriendsListDataSource.h"
#import "QMUsersService.h"
#import "QMFriendListCell.h"
#import "QMSearchGlobalCell.h"
#import "QMNotResultCell.h"
#import "QMApi.h"
#import "QMUsersService.h"
#import "SVProgressHud.h"
#import "QMChatReceiver.h"

static NSString *const kFriendsListCellIdentifier = @"QMFriendListCell";
static NSString *const kQMSearchGlobalCellIdentifier = @"QMSearchGlobalCell";
static NSString *const kQMNotResultCellIdentifier = @"QMNotResultCell";

@interface QMFriendsListDataSource()

<QMFriendListCellDelegate>

@property (strong, nonatomic) NSArray *searchList;
@property (strong, nonatomic) NSArray *friendList;
@property (weak, nonatomic) UITableView *tableView;

@end

@implementation QMFriendsListDataSource

@synthesize friendList = _friendList;

- (void)dealloc {
    NSLog(@"%@ - %@",  NSStringFromSelector(_cmd), self);
}

- (instancetype)initWithTableView:(UITableView *)tableView {
    
    self = [super init];
    if (self) {
        
        self.tableView = tableView;
        self.tableView.dataSource = self;
        
        self.searchList = [NSArray array];
        
        __weak __typeof(self)weakSelf = self;
        void(^retrive)(void) = ^() {
            [[QMApi instance] retrieveFriendsIfNeeded:^(BOOL updated) {
                [weakSelf reloadDatasource];
            }];
        };
                
        [[QMChatReceiver instance] chatContactListWilChangeWithTarget:self block:retrive];
        
        [[QMChatReceiver instance] chatDidReceiveContactAddRequestWithTarget:self block:^(NSUInteger userID) {
            BOOL success = [[QMApi instance] confirmAddContactRequest:userID];
            if (success) {
                NSLog(@"Auto approve userID - %d", userID);
            }
        }];
    }
    
    return self;
}

- (void)setFriendList:(NSArray *)friendList {
    _friendList = [self sortUsersByFullname:friendList];
}

- (NSArray *)friendList {
    
    if (self.searchActive && self.searchText.length > 0) {
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.fullName CONTAINS[cd] %@", self.searchText];
        NSArray *filtered = [_friendList filteredArrayUsingPredicate:predicate];
        
        return filtered;
    }
    return _friendList;
}

- (void)reloadDatasource {
    
    self.friendList = [QMApi instance].friends;
    [self.tableView reloadData];
    
    if (!self.searchActive) {
        
        self.tableView.tableFooterView =
        self.friendList.count == 0 ? [self.tableView dequeueReusableCellWithIdentifier:kQMNotResultCellIdentifier] : [[UIView alloc] initWithFrame:CGRectZero];
    }
}

- (NSArray *)sortUsersByFullname:(NSArray *)users {
    
    NSSortDescriptor *fullNameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"fullName" ascending:YES];
    NSArray *sortedUsers = [users sortedArrayUsingDescriptors:@[fullNameDescriptor]];
    
    return sortedUsers;
}

- (void)globalSearch {

    __weak __typeof(self)weakSelf = self;
    QBUUserPagedResultBlock userPagedBlock = ^(QBUUserPagedResult *pagedResult) {

        if (pagedResult.success) {
            
            NSArray *users = [weakSelf sortUsersByFullname:pagedResult.users];
            //Remove current user from search result
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.ID != %d", [QMApi instance].currentUser.ID];
            weakSelf.searchList = [users filteredArrayUsingPredicate:predicate];
            [weakSelf.tableView reloadData];
        }
        
        [SVProgressHUD dismiss];
    };
    
    PagedRequest *request = [[PagedRequest alloc] init];
    request.page = 1;
    request.perPage = 100;
    
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    
    if (self.searchText.length == 0) {
        [[QMApi instance].usersService retrieveUsersWithPagedRequest:request completion:userPagedBlock];
    } else {
        [[QMApi instance].usersService retrieveUsersWithFullName:self.searchText pagedRequest:request completion:userPagedBlock];
    }
}

- (void)setSearchActive:(BOOL)searchActive {
    
    if (searchActive != _searchActive) {
        _searchActive = searchActive;
        
        self.tableView.tableFooterView = _searchActive ?
        [self.tableView dequeueReusableCellWithIdentifier:kQMSearchGlobalCellIdentifier] :
        [[UIView alloc] initWithFrame:CGRectZero];
        
        if (!_searchActive)  {
            self.searchList = nil;
        }
        [self.tableView reloadData];
    }
}

- (void)setSearchText:(NSString *)searchText {
    
    if (_searchText != searchText) {
        _searchText = searchText;
        
        if (self.friendList.count + self.searchList.count > 0) {
            [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
        }
        [self.tableView reloadData];
    }
}

#pragma mark - UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    return (self.searchActive) ? ((section == 0) ? kTableHeaderFriendsString : kTableHeaderAllUsersString) : @"";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [self usersAtSections:section].count;
}

- (NSArray *)usersAtSections:(NSUInteger)section {
    
    return (section == 0 ) ? self.friendList : self.searchList;
}

- (QBUUser *)userAtIndexPath:(NSIndexPath *)indexPath {
    
    NSArray *users = [self usersAtSections:indexPath.section];
    QBUUser *user = users[indexPath.row];

    return user;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    QMFriendListCell *cell = [tableView dequeueReusableCellWithIdentifier:kFriendsListCellIdentifier];
    NSArray *datasource = [self usersAtSections:indexPath.section];
    QBUUser *user = datasource[indexPath.row];
    
    cell.contactlistItem = [[QMApi instance] contactItemWithUserID:user.ID];
    cell.userData = user;
    cell.searchText = self.searchText;
    cell.delegate = self;
    
    return cell;
}

#pragma mark - QMFriendListCellDelegate

- (void)friendListCell:(QMFriendListCell *)cell pressAddBtn:(UIButton *)sender {
    
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSArray *datasource = [self usersAtSections:indexPath.section];
    QBUUser *user = datasource[indexPath.row];
    
    [[QMApi instance] addUserToContactListRequest:user.ID];
}

@end
