# LDScrollViewForm

[![Version](http://cocoapod-badges.herokuapp.com/v/LDScrollViewForm/badge.png)](http://cocoadocs.org/docsets/LDScrollViewForm)
[![Platform](http://cocoapod-badges.herokuapp.com/p/LDScrollViewForm/badge.png)](http://cocoadocs.org/docsets/LDScrollViewForm)

## Usage

To create a form : 

* Make your form by adding subviews in a UIScrollView (like UITextField, UITextView, UILabel ....)
* Your View Controller have to extend LDScrollViewController
* Finally you need to register the UIScrollView with the method `[self setForm:myScrollView]`

## Requirements

## Installation

LDScrollViewForm is available through [CocoaPods](http://cocoapods.org), to install
it simply add the following line to your Podfile:

    pod "LDScrollViewForm"

## Author

Damien Legrand, 

## License

LDScrollViewForm is available under the MIT license. See the LICENSE file for more info.