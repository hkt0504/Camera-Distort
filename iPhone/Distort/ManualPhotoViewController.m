//
//  ManualPhotoViewController.m
//  Distort
//
//  Created by Michel Han on 8/27/14.
//  Copyright (c) 2014 Michel Han. All rights reserved.
//

#import "ManualPhotoViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "PhotoCell.h"
#import "ManualMainController.h"
#import "AlbumTableViewController.h"

@interface ManualPhotoViewController ()
{
    NSMutableArray *assetList;
    AlbumTableViewController *albumController;
    NSString *albumName;
}
@end

@implementation ManualPhotoViewController

+ (ALAssetsLibrary *)defaultAssetsLibrary
{
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary *library = nil;
    dispatch_once(&pred, ^{
        library = [[ALAssetsLibrary alloc] init];
    });
    return library;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) selectedAlbum:(NSString *)name
{
    if(albumName != name)
    {
        [assetList removeAllObjects];
        [self.collectionView reloadData];
    }
    
    albumName = name;
}

- (void) viewDidAppear:(BOOL)animated
{
    if(assetList)
       [assetList removeAllObjects];
    else
        assetList = [[NSMutableArray alloc] init];
    
    ALAssetsLibrary *library = [ManualPhotoViewController defaultAssetsLibrary] ;
	
	[library enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if (group) {
            if(albumName && ![albumName isEqualToString:[group valueForProperty:ALAssetsGroupPropertyName]])
                return;
            
            [group setAssetsFilter:[ALAssetsFilter allPhotos]];
            [group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop) {
                if (asset) {
                    [assetList addObject:asset];
                }
            }];
        }
        else
        {
            NSLog(@"Done! Count = %lu", (unsigned long)assetList.count);
            [self.collectionView reloadData];
        }
	}
    failureBlock:^(NSError *error) {
        NSLog(@"error enumerating AssetLibrary groups %@\n", error);
    }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    albumController = nil;
    albumName = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)touchCancel:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}
- (IBAction)touchAlbum:(id)sender {
    if(!albumController)
    {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        albumController = [storyboard instantiateViewControllerWithIdentifier:@"AlbumController"];
        albumController.delegate = self;
    }
    [self.navigationController pushViewController:albumController animated:YES];
}

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section
{
    return assetList.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PhotoCell *cell = (PhotoCell *)[self.collectionView dequeueReusableCellWithReuseIdentifier:@"PhotoCell" forIndexPath:indexPath];
    
    ALAsset *asset = assetList[assetList.count - indexPath.row - 1];
    cell.asset = asset;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    PhotoCell* cell=(PhotoCell*)[self.collectionView cellForItemAtIndexPath:indexPath];

    if(cell)
    {
        [cell.photoImageView setAlpha:0.5f];

        NSArray *array = self.navigationController.viewControllers;
        ManualMainController * controller = nil;
        if(!array)
            return;
        for(int i = 0; i <array.count; i++)
        {
            if([[array objectAtIndex:i] isKindOfClass:[ManualMainController class]])
                controller = [array objectAtIndex:i];
        }
        
        if(!controller)
        {
            [self.navigationController popToRootViewControllerAnimated:YES];
            return;
        }
        
        if(cell.asset)
        {
            ALAssetRepresentation *representation = [cell.asset defaultRepresentation];
            
            if(representation)
            {
                [controller setNewImage:[representation fullResolutionImage]];
            }
        }
        
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}
@end
