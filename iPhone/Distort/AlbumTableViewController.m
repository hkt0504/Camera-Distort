//
//  AlbumTableViewController.m
//  Distort
//
//  Created by Michel Han on 9/10/14.
//  Copyright (c) 2014 Michel Han. All rights reserved.
//

#import "AlbumTableViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface AlbumTableViewController ()
{
    NSMutableArray *albumArray;
}
@end

@implementation AlbumTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [self.navigationItem setHidesBackButton:YES];
    albumArray = [[NSMutableArray alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) viewDidAppear:(BOOL)animated
{
    if(albumArray)
       [albumArray removeAllObjects];
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary *library = nil;
    dispatch_once(&pred, ^{
        library = [[ALAssetsLibrary alloc] init];
    });
    
    ALAssetsLibraryGroupsEnumerationResultsBlock listGroupBlock = ^(ALAssetsGroup *group, BOOL *stop) {
        if (group) {
            [albumArray addObject:group];
        }
        else
        {
            [self.tableView reloadData];
            NSLog(@"%@", albumArray);
        }
    };
    NSUInteger groupTypes = ALAssetsGroupAll;
    [library enumerateGroupsWithTypes:groupTypes usingBlock:listGroupBlock failureBlock:nil];
}

- (IBAction)touchCancel:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return albumArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AlbumCell" forIndexPath:indexPath];
    
    // Configure the cell...
    // Configuration des cellules
    if(indexPath.row < albumArray.count)
    {
        ALAssetsGroup *group = [albumArray objectAtIndex:indexPath.row];
        cell.textLabel.text = [group valueForProperty:ALAssetsGroupPropertyName];
        cell.imageView.image = [UIImage imageWithCGImage:group.posterImage];
    }

    NSLog(@"%@", cell.textLabel.text);

    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row < albumArray.count)
    {
        ALAssetsGroup *group = [albumArray objectAtIndex:indexPath.row];
        [self.delegate selectedAlbum:[group valueForProperty:ALAssetsGroupPropertyName]];
    }
    else
        [self.delegate selectedAlbum:nil];
    
    [self.navigationController popViewControllerAnimated:YES];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
