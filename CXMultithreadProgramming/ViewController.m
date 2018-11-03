//
//  ViewController.m
//  CXMultithreadProgramming
//
//  Created by 陈晓辉 on 2018/10/30.
//  Copyright © 2018年 陈晓辉. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    
    #pragma mark ---------- 顺序执行 ----------
    //opration 添加依赖
//    [self opration_sort_addDependency];
    //GCD
//        [self gcd_sort_semaphore];
    
    #pragma mark ---------- 随机顺序(全部请求完成后,再统一操作) ----------
    //GCD
//    [self gcd_random_semaphore];
//    [self gcd_random_enter];
    
    #pragma mark ---------- 控制最大并发数 ----------
    //opration
//    [self operation_setMaxConcurrentOperationCount];
    //GCD
//    [self gcd_semaphore];
}


#pragma mark ---------- 顺序执行 ----------
//MARK: opration 添加依赖 - 顺序执行
- (void)opration_sort_addDependency {
    
    // 1.创建队列
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
    // 2.创建操作
    NSBlockOperation *op1 = [NSBlockOperation blockOperationWithBlock:^{
        for (int i = 0; i < 2; i++) {
            [NSThread sleepForTimeInterval:2]; // 模拟耗时操作
            NSLog(@"1---%@", [NSThread currentThread]); // 打印当前线程
        }
    }];
    NSBlockOperation *op2 = [NSBlockOperation blockOperationWithBlock:^{
        for (int i = 0; i < 2; i++) {
            [NSThread sleepForTimeInterval:2]; // 模拟耗时操作
            NSLog(@"2---%@", [NSThread currentThread]); // 打印当前线程
        }
    }];
    
    // 3.添加依赖
    [op2 addDependency:op1]; // 让op2 依赖于 op1，则先执行op1，在执行op2
    
    // 4.添加操作到队列中
    [queue addOperation:op1];
    [queue addOperation:op2];
}
//MARK: GCD - 顺序执行 - 信号量
- (void)gcd_sort_semaphore {
    
    dispatch_queue_t queue = dispatch_queue_create("testBlock", NULL);
    
    //创建信号量, 并这是并发数为 1
    dispatch_semaphore_t sem = dispatch_semaphore_create(1);
    dispatch_async(queue, ^{
        
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"1");
            dispatch_semaphore_signal(sem);
        });
    });
    dispatch_async(queue, ^{
        
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"2");
            dispatch_semaphore_signal(sem);
        });
    });
    dispatch_async(queue, ^{
        
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"3");
            dispatch_semaphore_signal(sem);
        });
    });
    dispatch_async(queue, ^{
        
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"4");
            dispatch_semaphore_signal(sem);
        });
    });
}

#pragma mark ---------- 随机顺序 ----------
//MARK: GCD - 随机顺序 - 信号量
- (void)gcd_random_semaphore {
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t group = dispatch_group_create();
    
    //创建一个semaphore  -- 设置最大并发数
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    dispatch_group_async(group, queue, ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            NSLog(@"请求一");
            //发送一个信号  --  信号量+1
            dispatch_semaphore_signal(sem);
        });
        //等待信号  --  信号量-1 监听到信号量由0变为1后，跳出等待，并且结束当前group队列
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    });
    dispatch_group_async(group, queue, ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            NSLog(@"请求二");
            dispatch_semaphore_signal(sem);
        });
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    });
    
    dispatch_group_async(group, queue, ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            NSLog(@"请求三");
            dispatch_semaphore_signal(sem);
        });
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    });
    
    //在分组的所有任务完成后触发
    dispatch_group_notify(group, queue, ^{
        
        NSLog(@"请求完成");
    });
}
//MARK: GCD - 随机顺序 - enter 和 leave
- (void)gcd_random_enter {
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_async(group, queue, ^{
        
        /*
         dispatch_group_enter 和 dispatch_group_leave 一般是成对出现的, 进入一次，就得离开一次。
         也就是说，当离开和进入的次数相同时，就代表任务组完成了。
         如果enter比leave多，那就是没完成，如果leave调用的次数错了， 会崩溃的；
         */
        dispatch_group_enter(group);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            NSLog(@"请求一");
            dispatch_group_leave(group);
        });
    });
    
    dispatch_group_async(group, queue, ^{
        
        dispatch_group_enter(group);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            NSLog(@"请求二");
            dispatch_group_leave(group);
        });
    });
    
    dispatch_group_async(group, queue, ^{
        
        dispatch_group_enter(group);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            NSLog(@"请求三");
            dispatch_group_leave(group);
        });
    });
    //在分组的所有任务完成后触发
    dispatch_group_notify(group, queue, ^{
        
        NSLog(@"请求完成");
    });
}

#pragma mark ---------- 控制最大并发数 ----------
//MARK: GCD - 控制最大并发数
- (void)gcd_semaphore {
    
    dispatch_group_t group = dispatch_group_create();
    
    //创建一个semaphore  -- 设置最大并发数
    dispatch_semaphore_t semaohore = dispatch_semaphore_create(2);
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    for (int i = 0; i < 50; i++) {
        
        //等待信号  --  信号量-1 监听到信号量由0变为1后，跳出等待，并且结束当前group队列
        dispatch_semaphore_wait(semaohore, DISPATCH_TIME_FOREVER);
        dispatch_group_async(group, queue, ^{
            
            NSLog(@"%i - %@", i,[NSThread currentThread]);
            sleep(1);
            
            //发送一个信号  --  信号量+1
            dispatch_semaphore_signal(semaohore);
        });
    }
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
}

//MARK: operation -  MaxConcurrentOperationCount（最大并发操作数）
- (void)operation_setMaxConcurrentOperationCount {
    
    // 1.创建队列
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
    // 2.设置最大并发操作数
//    queue.maxConcurrentOperationCount = 1; // 串行队列
    queue.maxConcurrentOperationCount = 2; // 并发队列
    // queue.maxConcurrentOperationCount = 8; // 并发队列
    
    // 3.添加操作
    [queue addOperationWithBlock:^{
        for (int i = 0; i < 2; i++) {
            [NSThread sleepForTimeInterval:2]; // 模拟耗时操作
            NSLog(@"1---%@", [NSThread currentThread]); // 打印当前线程
        }
    }];
    [queue addOperationWithBlock:^{
        for (int i = 0; i < 2; i++) {
            [NSThread sleepForTimeInterval:2]; // 模拟耗时操作
            NSLog(@"2---%@", [NSThread currentThread]); // 打印当前线程
        }
    }];
    [queue addOperationWithBlock:^{
        for (int i = 0; i < 2; i++) {
            [NSThread sleepForTimeInterval:2]; // 模拟耗时操作
            NSLog(@"3---%@", [NSThread currentThread]); // 打印当前线程
        }
    }];
    [queue addOperationWithBlock:^{
        for (int i = 0; i < 2; i++) {
            [NSThread sleepForTimeInterval:2]; // 模拟耗时操作
            NSLog(@"4---%@", [NSThread currentThread]); // 打印当前线程
        }
    }];
}


@end
