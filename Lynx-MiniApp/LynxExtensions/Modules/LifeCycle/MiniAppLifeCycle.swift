//
//  MiniAppLifeCycle.swift
//  ttest
//
//  Created by 김수환 on 11/1/25.
//
// https://www.w3.org/TR/miniapp-lifecycle/

import Foundation


//    global application lifecycle events
//    MiniApp initialization
//
//    MiniApp running in foreground
//
//    MiniApp running in background
//
//    MiniApp in error
//
//    MiniApp unloading

//    global application lifecycle states
//    launched
//    shown
//    hidden
//    error
//    unloaded

//    interface Global {
//     readonly attribute GlobalState globalState;
//     readonly attribute InputObject inputObject;
//     readonly attribute LifecycleError lifecycleError;
//     attribute EventHandler ongloballaunched; -> globalState.launched
//     attribute EventHandler onglobalshown; -> globalState.shown
//     attribute EventHandler onglobalhidden; -> globalState.hidden
//     attribute EventHandler onglobalerror; -> globalState.error
//     attribute EventHandler onglobalunloaded; -> globalState.unload
//    };

//    interface LifecycleError {
//        readonly attribute DOMString errorDescription;
//        readonly attribute DOMString lang;
//        readonly attribute TextDirection dir;
//    };



//    MiniApp Page Lifecycle Events
//    MiniApp page loading
//
//    MiniApp page first render ready
//
//    MiniApp page running in foreground
//
//    MiniApp page running in background
//
//    MiniApp page unloading


//    "loaded", "ready", "shown", "hidden", "unloaded"

//    interface Page {
//        readonly attribute PageState pageState;
//        readonly attribute PageInputObject pageInputObject;
//        attribute EventHandler onpageloaded;
//        attribute EventHandler onpageready;
//        attribute EventHandler onpageshown;
//        attribute EventHandler onpagehidden;
//        attribute EventHandler onpageunloaded;
//    };
