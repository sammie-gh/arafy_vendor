import 'dart:io';

import 'package:cool_alert/cool_alert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:fuodz/models/menu.dart';
import 'package:fuodz/models/product_category.dart';
import 'package:fuodz/models/vendor.dart';
import 'package:fuodz/requests/product.request.dart';
import 'package:fuodz/requests/vendor.request.dart';
import 'package:fuodz/services/auth.service.dart';
import 'package:fuodz/services/html.service.dart';
import 'package:fuodz/view_models/base.view_model.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:localize_and_translate/localize_and_translate.dart';

class NewProductViewModel extends MyBaseViewModel {
  //
  NewProductViewModel(BuildContext context) {
    this.viewContext = context;
  }

  //
  ProductRequest productRequest = ProductRequest();
  VendorRequest vendorRequest = VendorRequest();
  QuillController quilController = QuillController.basic();
  List<ProductCategory> categories = [];
  List<ProductCategory> subCategories = [];
  List<ProductCategory> unFilterSubCategories = [];
  List<Menu> menus = [];
  List<File> selectedPhotos;

  void initialise() {
    fetchProductCategories();
    fetchProductSubCategories();
    fetchMenus();
  }

  //
  fetchProductCategories() async {
    setBusyForObject(categories, true);

    try {
      categories = await productRequest.getProductCategories(
        vendorTypeId:
            (await AuthServices.getCurrentVendor(force: true)).vendorType.id,
      );
      clearErrors();
    } catch (error) {
      print("Categories Error ==> $error");
      setError(error);
    }

    setBusyForObject(categories, false);
  }

  fetchProductSubCategories() async {
    setBusyForObject(subCategories, true);

    try {
      unFilterSubCategories = await productRequest.getProductCategories(
        subCat: true,
        vendorTypeId:
            (await AuthServices.getCurrentVendor(force: true)).vendorType.id,
      );
      clearErrors();
    } catch (error) {
      print("subCategories Error ==> $error");
      setError(error);
    }

    setBusyForObject(subCategories, false);
  }

  fetchMenus() async {
    setBusyForObject(menus, true);

    try {
      final response = await vendorRequest.getVendorDetails();
      final vendor = Vendor.fromJson(response["vendor"]);
      menus = vendor.menus;
      print("$menus");
      clearErrors();
    } catch (error) {
      print("menus Error ==> $error");
      setError(error);
    }

    setBusyForObject(menus, false);
  }

  //
  onImagesSelected(List<File> files) {
    selectedPhotos = files;
    notifyListeners();
  }

  //
  processNewProduct() async {
    if (formBuilderKey.currentState.saveAndValidate()) {
      //
      setBusy(true);

      try {
        Map<String, dynamic> productData = Map.from(
          formBuilderKey.currentState.value,
        );
        productData.addAll({
          "description": HtmlService.quillDeltaToHtml(
            quilController.document.toDelta(),
          ),
        });

        final apiResponse = await productRequest.newProduct(
          productData,
          photos: selectedPhotos,
        );
        //
        //show dialog to present state
        CoolAlert.show(
            context: viewContext,
            type: apiResponse.allGood
                ? CoolAlertType.success
                : CoolAlertType.error,
            title: "New Product".tr(),
            text: apiResponse.message,
            onConfirmBtnTap: () {
              viewContext.pop();
              if (apiResponse.allGood) {
                viewContext.pop(true);
              }
            });
        clearErrors();
      } catch (error) {
        print("New product Error ==> $error");
        setError(error);
      }

      setBusy(false);
    }
  }

  //
  void filterSubcategories(List<String> categoryIds) {
    subCategories = unFilterSubCategories.where(
      (e) {
        return categoryIds.contains(e.categoryId.toString());
      },
    ).toList();
    notifyListeners();
  }
}
