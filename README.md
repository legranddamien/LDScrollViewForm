# LDScrollViewForm

[![Version](http://cocoapod-badges.herokuapp.com/v/LDScrollViewForm/badge.png)](http://cocoadocs.org/docsets/LDScrollViewForm)
[![Platform](http://cocoapod-badges.herokuapp.com/p/LDScrollViewForm/badge.png)](http://cocoadocs.org/docsets/LDScrollViewForm)

LDScrollViewForm is ARC and work on iOS6+ (may work on iOS5 but not tested)

## Features

* Generate automatically the contentSize of the UIScrollView
* Keyboard Avoiding
* Go to the next UITextField/UItextView by touching return on a UITextFiled
* Adapte the size of a UITextView to show the full text
* Limit the number of characters in a UITextView

## Usage

To create a form : 

* Make your form by adding subviews in a UIScrollView (like UITextField, UITextView, UILabel ....)
* Your View Controller have to extend LDScrollViewController
* Finally you need to register the UIScrollView with the method `setForm:`
* If you need to not include a view in the calculation of the contentSize (i.e. a Bottom Reveal View) use the method `addUnsuportedView:`
* If you need to have a margin between the keyboard and the scroll view set the `heightAboveKeyboard` with a CGFloat
* It's also possible to refresh the views (if you programmatically add texts in UITextViews) with the method `updateForm`

## Installation

LDScrollViewForm is available through [CocoaPods](http://cocoapods.org), to install
it simply add the following line to your Podfile:

    pod "LDScrollViewForm"

## Author

Damien Legrand, @damien_legrand

## License

LDScrollViewForm is available under the MIT license. See the LICENSE file for more info.