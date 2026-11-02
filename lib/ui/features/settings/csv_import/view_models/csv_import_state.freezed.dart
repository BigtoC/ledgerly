// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'csv_import_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CsvImportState {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CsvImportState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'CsvImportState()';
}


}

/// @nodoc
class $CsvImportStateCopyWith<$Res>  {
$CsvImportStateCopyWith(CsvImportState _, $Res Function(CsvImportState) __);
}


/// Adds pattern-matching-related methods to [CsvImportState].
extension CsvImportStatePatterns on CsvImportState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CsvImportIdle value)?  idle,TResult Function( CsvImportLoading value)?  loading,TResult Function( CsvImportPreview value)?  preview,TResult Function( CsvImportCommitting value)?  committing,TResult Function( CsvImportDone value)?  done,TResult Function( CsvImportFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CsvImportIdle() when idle != null:
return idle(_that);case CsvImportLoading() when loading != null:
return loading(_that);case CsvImportPreview() when preview != null:
return preview(_that);case CsvImportCommitting() when committing != null:
return committing(_that);case CsvImportDone() when done != null:
return done(_that);case CsvImportFailure() when failure != null:
return failure(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CsvImportIdle value)  idle,required TResult Function( CsvImportLoading value)  loading,required TResult Function( CsvImportPreview value)  preview,required TResult Function( CsvImportCommitting value)  committing,required TResult Function( CsvImportDone value)  done,required TResult Function( CsvImportFailure value)  failure,}){
final _that = this;
switch (_that) {
case CsvImportIdle():
return idle(_that);case CsvImportLoading():
return loading(_that);case CsvImportPreview():
return preview(_that);case CsvImportCommitting():
return committing(_that);case CsvImportDone():
return done(_that);case CsvImportFailure():
return failure(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CsvImportIdle value)?  idle,TResult? Function( CsvImportLoading value)?  loading,TResult? Function( CsvImportPreview value)?  preview,TResult? Function( CsvImportCommitting value)?  committing,TResult? Function( CsvImportDone value)?  done,TResult? Function( CsvImportFailure value)?  failure,}){
final _that = this;
switch (_that) {
case CsvImportIdle() when idle != null:
return idle(_that);case CsvImportLoading() when loading != null:
return loading(_that);case CsvImportPreview() when preview != null:
return preview(_that);case CsvImportCommitting() when committing != null:
return committing(_that);case CsvImportDone() when done != null:
return done(_that);case CsvImportFailure() when failure != null:
return failure(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function()?  loading,TResult Function( String fileName,  int importCount,  DateTime? firstRecordedAt,  DateTime? lastRecordedAt,  List<CsvRowError> errors,  List<CsvAccountMatch> accounts,  List<CsvCategoryEntry> categories,  int duplicateCount,  bool canCommit)?  preview,TResult Function()?  committing,TResult Function( CsvImportResult result,  int invalidRowCount)?  done,TResult Function( CsvFileErrorKind kind,  List<String> missingColumns)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CsvImportIdle() when idle != null:
return idle();case CsvImportLoading() when loading != null:
return loading();case CsvImportPreview() when preview != null:
return preview(_that.fileName,_that.importCount,_that.firstRecordedAt,_that.lastRecordedAt,_that.errors,_that.accounts,_that.categories,_that.duplicateCount,_that.canCommit);case CsvImportCommitting() when committing != null:
return committing();case CsvImportDone() when done != null:
return done(_that.result,_that.invalidRowCount);case CsvImportFailure() when failure != null:
return failure(_that.kind,_that.missingColumns);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function()  loading,required TResult Function( String fileName,  int importCount,  DateTime? firstRecordedAt,  DateTime? lastRecordedAt,  List<CsvRowError> errors,  List<CsvAccountMatch> accounts,  List<CsvCategoryEntry> categories,  int duplicateCount,  bool canCommit)  preview,required TResult Function()  committing,required TResult Function( CsvImportResult result,  int invalidRowCount)  done,required TResult Function( CsvFileErrorKind kind,  List<String> missingColumns)  failure,}) {final _that = this;
switch (_that) {
case CsvImportIdle():
return idle();case CsvImportLoading():
return loading();case CsvImportPreview():
return preview(_that.fileName,_that.importCount,_that.firstRecordedAt,_that.lastRecordedAt,_that.errors,_that.accounts,_that.categories,_that.duplicateCount,_that.canCommit);case CsvImportCommitting():
return committing();case CsvImportDone():
return done(_that.result,_that.invalidRowCount);case CsvImportFailure():
return failure(_that.kind,_that.missingColumns);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function()?  loading,TResult? Function( String fileName,  int importCount,  DateTime? firstRecordedAt,  DateTime? lastRecordedAt,  List<CsvRowError> errors,  List<CsvAccountMatch> accounts,  List<CsvCategoryEntry> categories,  int duplicateCount,  bool canCommit)?  preview,TResult? Function()?  committing,TResult? Function( CsvImportResult result,  int invalidRowCount)?  done,TResult? Function( CsvFileErrorKind kind,  List<String> missingColumns)?  failure,}) {final _that = this;
switch (_that) {
case CsvImportIdle() when idle != null:
return idle();case CsvImportLoading() when loading != null:
return loading();case CsvImportPreview() when preview != null:
return preview(_that.fileName,_that.importCount,_that.firstRecordedAt,_that.lastRecordedAt,_that.errors,_that.accounts,_that.categories,_that.duplicateCount,_that.canCommit);case CsvImportCommitting() when committing != null:
return committing();case CsvImportDone() when done != null:
return done(_that.result,_that.invalidRowCount);case CsvImportFailure() when failure != null:
return failure(_that.kind,_that.missingColumns);case _:
  return null;

}
}

}

/// @nodoc


class CsvImportIdle implements CsvImportState {
  const CsvImportIdle();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CsvImportIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'CsvImportState.idle()';
}


}




/// @nodoc


class CsvImportLoading implements CsvImportState {
  const CsvImportLoading();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CsvImportLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'CsvImportState.loading()';
}


}




/// @nodoc


class CsvImportPreview implements CsvImportState {
  const CsvImportPreview({required this.fileName, required this.importCount, this.firstRecordedAt, this.lastRecordedAt, required  List<CsvRowError> errors, required  List<CsvAccountMatch> accounts, required  List<CsvCategoryEntry> categories, required this.duplicateCount, required this.canCommit}): _errors = errors,_accounts = accounts,_categories = categories;
  

 final  String fileName;
/// Rows that will be inserted: valid and not already present.
 final  int importCount;
/// Recorded At range of those rows; null when [importCount] is 0.
 final  DateTime? firstRecordedAt;
 final  DateTime? lastRecordedAt;
/// Skipped rows, sorted by line.
 final  List<CsvRowError> _errors;
/// Skipped rows, sorted by line.
 List<CsvRowError> get errors {
  if (_errors is EqualUnmodifiableListView) return _errors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_errors);
}

/// One entry per distinct CSV Account value among the rows to import.
/// [CsvAccountMatch.resolution] is the current choice.
 final  List<CsvAccountMatch> _accounts;
/// One entry per distinct CSV Account value among the rows to import.
/// [CsvAccountMatch.resolution] is the current choice.
 List<CsvAccountMatch> get accounts {
  if (_accounts is EqualUnmodifiableListView) return _accounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_accounts);
}

/// One entry per distinct CSV Category value among the rows to import.
 final  List<CsvCategoryEntry> _categories;
/// One entry per distinct CSV Category value among the rows to import.
 List<CsvCategoryEntry> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

 final  int duplicateCount;
/// Every account is resolved and at least one row will be inserted.
 final  bool canCommit;

/// Create a copy of CsvImportState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CsvImportPreviewCopyWith<CsvImportPreview> get copyWith => _$CsvImportPreviewCopyWithImpl<CsvImportPreview>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CsvImportPreview&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.importCount, importCount) || other.importCount == importCount)&&(identical(other.firstRecordedAt, firstRecordedAt) || other.firstRecordedAt == firstRecordedAt)&&(identical(other.lastRecordedAt, lastRecordedAt) || other.lastRecordedAt == lastRecordedAt)&&const DeepCollectionEquality().equals(other.errors, _errors)&&const DeepCollectionEquality().equals(other.accounts, _accounts)&&const DeepCollectionEquality().equals(other.categories, _categories)&&(identical(other.duplicateCount, duplicateCount) || other.duplicateCount == duplicateCount)&&(identical(other.canCommit, canCommit) || other.canCommit == canCommit));
}


@override
int get hashCode {
    return Object.hash(runtimeType,fileName,importCount,firstRecordedAt,lastRecordedAt,const DeepCollectionEquality().hash(_errors),const DeepCollectionEquality().hash(_accounts),const DeepCollectionEquality().hash(_categories),duplicateCount,canCommit);
}

@override
String toString() {
    return 'CsvImportState.preview(fileName: $fileName, importCount: $importCount, firstRecordedAt: $firstRecordedAt, lastRecordedAt: $lastRecordedAt, errors: $errors, accounts: $accounts, categories: $categories, duplicateCount: $duplicateCount, canCommit: $canCommit)';
}


}

/// @nodoc
abstract mixin class $CsvImportPreviewCopyWith<$Res> implements $CsvImportStateCopyWith<$Res> {
  factory $CsvImportPreviewCopyWith(CsvImportPreview value, $Res Function(CsvImportPreview) _then) = _$CsvImportPreviewCopyWithImpl;
@useResult
$Res call({
 String fileName, int importCount, DateTime? firstRecordedAt, DateTime? lastRecordedAt, List<CsvRowError> errors, List<CsvAccountMatch> accounts, List<CsvCategoryEntry> categories, int duplicateCount, bool canCommit
});




}
/// @nodoc
class _$CsvImportPreviewCopyWithImpl<$Res>
    implements $CsvImportPreviewCopyWith<$Res> {
  _$CsvImportPreviewCopyWithImpl(this._self, this._then);

  final CsvImportPreview _self;
  final $Res Function(CsvImportPreview) _then;

/// Create a copy of CsvImportState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? fileName = null,Object? importCount = null,Object? firstRecordedAt = freezed,Object? lastRecordedAt = freezed,Object? errors = null,Object? accounts = null,Object? categories = null,Object? duplicateCount = null,Object? canCommit = null,}) {
  return _then(CsvImportPreview(
fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,importCount: null == importCount ? _self.importCount : importCount // ignore: cast_nullable_to_non_nullable
as int,firstRecordedAt: freezed == firstRecordedAt ? _self.firstRecordedAt : firstRecordedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastRecordedAt: freezed == lastRecordedAt ? _self.lastRecordedAt : lastRecordedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,errors: null == errors ? _self._errors : errors // ignore: cast_nullable_to_non_nullable
as List<CsvRowError>,accounts: null == accounts ? _self._accounts : accounts // ignore: cast_nullable_to_non_nullable
as List<CsvAccountMatch>,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<CsvCategoryEntry>,duplicateCount: null == duplicateCount ? _self.duplicateCount : duplicateCount // ignore: cast_nullable_to_non_nullable
as int,canCommit: null == canCommit ? _self.canCommit : canCommit // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class CsvImportCommitting implements CsvImportState {
  const CsvImportCommitting();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CsvImportCommitting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'CsvImportState.committing()';
}


}




/// @nodoc


class CsvImportDone implements CsvImportState {
  const CsvImportDone({required this.result, required this.invalidRowCount});
  

 final  CsvImportResult result;
 final  int invalidRowCount;

/// Create a copy of CsvImportState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CsvImportDoneCopyWith<CsvImportDone> get copyWith => _$CsvImportDoneCopyWithImpl<CsvImportDone>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CsvImportDone&&(identical(other.result, result) || other.result == result)&&(identical(other.invalidRowCount, invalidRowCount) || other.invalidRowCount == invalidRowCount));
}


@override
int get hashCode {
    return Object.hash(runtimeType,result,invalidRowCount);
}

@override
String toString() {
    return 'CsvImportState.done(result: $result, invalidRowCount: $invalidRowCount)';
}


}

/// @nodoc
abstract mixin class $CsvImportDoneCopyWith<$Res> implements $CsvImportStateCopyWith<$Res> {
  factory $CsvImportDoneCopyWith(CsvImportDone value, $Res Function(CsvImportDone) _then) = _$CsvImportDoneCopyWithImpl;
@useResult
$Res call({
 CsvImportResult result, int invalidRowCount
});


$CsvImportResultCopyWith<$Res> get result;

}
/// @nodoc
class _$CsvImportDoneCopyWithImpl<$Res>
    implements $CsvImportDoneCopyWith<$Res> {
  _$CsvImportDoneCopyWithImpl(this._self, this._then);

  final CsvImportDone _self;
  final $Res Function(CsvImportDone) _then;

/// Create a copy of CsvImportState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? result = null,Object? invalidRowCount = null,}) {
  return _then(CsvImportDone(
result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as CsvImportResult,invalidRowCount: null == invalidRowCount ? _self.invalidRowCount : invalidRowCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of CsvImportState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CsvImportResultCopyWith<$Res> get result {
  
  return $CsvImportResultCopyWith<$Res>(_self.result, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}

/// @nodoc


class CsvImportFailure implements CsvImportState {
  const CsvImportFailure(this.kind, { List<String> missingColumns = const <String>[]}): _missingColumns = missingColumns;
  

 final  CsvFileErrorKind kind;
 final  List<String> _missingColumns;
@JsonKey() List<String> get missingColumns {
  if (_missingColumns is EqualUnmodifiableListView) return _missingColumns;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_missingColumns);
}


/// Create a copy of CsvImportState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CsvImportFailureCopyWith<CsvImportFailure> get copyWith => _$CsvImportFailureCopyWithImpl<CsvImportFailure>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CsvImportFailure&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other.missingColumns, _missingColumns));
}


@override
int get hashCode {
    return Object.hash(runtimeType,kind,const DeepCollectionEquality().hash(_missingColumns));
}

@override
String toString() {
    return 'CsvImportState.failure(kind: $kind, missingColumns: $missingColumns)';
}


}

/// @nodoc
abstract mixin class $CsvImportFailureCopyWith<$Res> implements $CsvImportStateCopyWith<$Res> {
  factory $CsvImportFailureCopyWith(CsvImportFailure value, $Res Function(CsvImportFailure) _then) = _$CsvImportFailureCopyWithImpl;
@useResult
$Res call({
 CsvFileErrorKind kind, List<String> missingColumns
});




}
/// @nodoc
class _$CsvImportFailureCopyWithImpl<$Res>
    implements $CsvImportFailureCopyWith<$Res> {
  _$CsvImportFailureCopyWithImpl(this._self, this._then);

  final CsvImportFailure _self;
  final $Res Function(CsvImportFailure) _then;

/// Create a copy of CsvImportState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? missingColumns = null,}) {
  return _then(CsvImportFailure(
null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as CsvFileErrorKind,missingColumns: null == missingColumns ? _self._missingColumns : missingColumns // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc
mixin _$CsvCategoryEntry {

 String get csvValue; int get rowCount; CategoryResolution get resolution;/// The target of an `existing` resolution; null otherwise.
 Category? get category;/// The income marker's targets: [salaryRowCount] rows go to
/// [salaryCategory], the rest to [otherIncomeCategory]. Null otherwise.
 Category? get salaryCategory; Category? get otherIncomeCategory; int get salaryRowCount;
/// Create a copy of CsvCategoryEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CsvCategoryEntryCopyWith<CsvCategoryEntry> get copyWith => _$CsvCategoryEntryCopyWithImpl<CsvCategoryEntry>(this as CsvCategoryEntry, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CsvCategoryEntry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CsvCategoryEntry&&(identical(other.csvValue, _this.csvValue) || other.csvValue == _this.csvValue)&&(identical(other.rowCount, _this.rowCount) || other.rowCount == _this.rowCount)&&(identical(other.resolution, _this.resolution) || other.resolution == _this.resolution)&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.salaryCategory, _this.salaryCategory) || other.salaryCategory == _this.salaryCategory)&&(identical(other.otherIncomeCategory, _this.otherIncomeCategory) || other.otherIncomeCategory == _this.otherIncomeCategory)&&(identical(other.salaryRowCount, _this.salaryRowCount) || other.salaryRowCount == _this.salaryRowCount));
}


@override
int get hashCode {
  final _this = this as CsvCategoryEntry;
  return Object.hash(runtimeType,_this.csvValue,_this.rowCount,_this.resolution,_this.category,_this.salaryCategory,_this.otherIncomeCategory,_this.salaryRowCount);
}

@override
String toString() {
  final _this = this as CsvCategoryEntry;
  return 'CsvCategoryEntry(csvValue: ${_this.csvValue}, rowCount: ${_this.rowCount}, resolution: ${_this.resolution}, category: ${_this.category}, salaryCategory: ${_this.salaryCategory}, otherIncomeCategory: ${_this.otherIncomeCategory}, salaryRowCount: ${_this.salaryRowCount})';
}


}

/// @nodoc
abstract mixin class $CsvCategoryEntryCopyWith<$Res>  {
  factory $CsvCategoryEntryCopyWith(CsvCategoryEntry value, $Res Function(CsvCategoryEntry) _then) = _$CsvCategoryEntryCopyWithImpl;
@useResult
$Res call({
 String csvValue, int rowCount, CategoryResolution resolution, Category? category, Category? salaryCategory, Category? otherIncomeCategory, int salaryRowCount
});


$CategoryResolutionCopyWith<$Res> get resolution;$CategoryCopyWith<$Res>? get category;$CategoryCopyWith<$Res>? get salaryCategory;$CategoryCopyWith<$Res>? get otherIncomeCategory;

}
/// @nodoc
class _$CsvCategoryEntryCopyWithImpl<$Res>
    implements $CsvCategoryEntryCopyWith<$Res> {
  _$CsvCategoryEntryCopyWithImpl(this._self, this._then);

  final CsvCategoryEntry _self;
  final $Res Function(CsvCategoryEntry) _then;

/// Create a copy of CsvCategoryEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? csvValue = null,Object? rowCount = null,Object? resolution = null,Object? category = freezed,Object? salaryCategory = freezed,Object? otherIncomeCategory = freezed,Object? salaryRowCount = null,}) {
  return _then(CsvCategoryEntry(
csvValue: null == csvValue ? _self.csvValue : csvValue // ignore: cast_nullable_to_non_nullable
as String,rowCount: null == rowCount ? _self.rowCount : rowCount // ignore: cast_nullable_to_non_nullable
as int,resolution: null == resolution ? _self.resolution : resolution // ignore: cast_nullable_to_non_nullable
as CategoryResolution,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as Category?,salaryCategory: freezed == salaryCategory ? _self.salaryCategory : salaryCategory // ignore: cast_nullable_to_non_nullable
as Category?,otherIncomeCategory: freezed == otherIncomeCategory ? _self.otherIncomeCategory : otherIncomeCategory // ignore: cast_nullable_to_non_nullable
as Category?,salaryRowCount: null == salaryRowCount ? _self.salaryRowCount : salaryRowCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of CsvCategoryEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryResolutionCopyWith<$Res> get resolution {
  
  return $CategoryResolutionCopyWith<$Res>(_self.resolution, (value) {
    return _then(_self.copyWith(resolution: value));
  });
}/// Create a copy of CsvCategoryEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryCopyWith<$Res>? get category {
    if (_self.category == null) {
    return null;
  }

  return $CategoryCopyWith<$Res>(_self.category!, (value) {
    return _then(_self.copyWith(category: value));
  });
}/// Create a copy of CsvCategoryEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryCopyWith<$Res>? get salaryCategory {
    if (_self.salaryCategory == null) {
    return null;
  }

  return $CategoryCopyWith<$Res>(_self.salaryCategory!, (value) {
    return _then(_self.copyWith(salaryCategory: value));
  });
}/// Create a copy of CsvCategoryEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryCopyWith<$Res>? get otherIncomeCategory {
    if (_self.otherIncomeCategory == null) {
    return null;
  }

  return $CategoryCopyWith<$Res>(_self.otherIncomeCategory!, (value) {
    return _then(_self.copyWith(otherIncomeCategory: value));
  });
}
}


/// Adds pattern-matching-related methods to [CsvCategoryEntry].
extension CsvCategoryEntryPatterns on CsvCategoryEntry {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CsvCategoryEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CsvCategoryEntry() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CsvCategoryEntry value)  $default,){
final _that = this;
switch (_that) {
case _CsvCategoryEntry():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CsvCategoryEntry value)?  $default,){
final _that = this;
switch (_that) {
case _CsvCategoryEntry() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String csvValue,  int rowCount,  CategoryResolution resolution,  Category? category,  Category? salaryCategory,  Category? otherIncomeCategory,  int salaryRowCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CsvCategoryEntry() when $default != null:
return $default(_that.csvValue,_that.rowCount,_that.resolution,_that.category,_that.salaryCategory,_that.otherIncomeCategory,_that.salaryRowCount);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String csvValue,  int rowCount,  CategoryResolution resolution,  Category? category,  Category? salaryCategory,  Category? otherIncomeCategory,  int salaryRowCount)  $default,) {final _that = this;
switch (_that) {
case _CsvCategoryEntry():
return $default(_that.csvValue,_that.rowCount,_that.resolution,_that.category,_that.salaryCategory,_that.otherIncomeCategory,_that.salaryRowCount);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String csvValue,  int rowCount,  CategoryResolution resolution,  Category? category,  Category? salaryCategory,  Category? otherIncomeCategory,  int salaryRowCount)?  $default,) {final _that = this;
switch (_that) {
case _CsvCategoryEntry() when $default != null:
return $default(_that.csvValue,_that.rowCount,_that.resolution,_that.category,_that.salaryCategory,_that.otherIncomeCategory,_that.salaryRowCount);case _:
  return null;

}
}

}

/// @nodoc


class _CsvCategoryEntry extends CsvCategoryEntry {
  const _CsvCategoryEntry({required this.csvValue, required this.rowCount, required this.resolution, this.category, this.salaryCategory, this.otherIncomeCategory, this.salaryRowCount = 0}): super._();
  

@override final  String csvValue;
@override final  int rowCount;
@override final  CategoryResolution resolution;
/// The target of an `existing` resolution; null otherwise.
@override final  Category? category;
/// The income marker's targets: [salaryRowCount] rows go to
/// [salaryCategory], the rest to [otherIncomeCategory]. Null otherwise.
@override final  Category? salaryCategory;
@override final  Category? otherIncomeCategory;
@override@JsonKey() final  int salaryRowCount;

/// Create a copy of CsvCategoryEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CsvCategoryEntryCopyWith<_CsvCategoryEntry> get copyWith => __$CsvCategoryEntryCopyWithImpl<_CsvCategoryEntry>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CsvCategoryEntry&&(identical(other.csvValue, csvValue) || other.csvValue == csvValue)&&(identical(other.rowCount, rowCount) || other.rowCount == rowCount)&&(identical(other.resolution, resolution) || other.resolution == resolution)&&(identical(other.category, category) || other.category == category)&&(identical(other.salaryCategory, salaryCategory) || other.salaryCategory == salaryCategory)&&(identical(other.otherIncomeCategory, otherIncomeCategory) || other.otherIncomeCategory == otherIncomeCategory)&&(identical(other.salaryRowCount, salaryRowCount) || other.salaryRowCount == salaryRowCount));
}


@override
int get hashCode {
    return Object.hash(runtimeType,csvValue,rowCount,resolution,category,salaryCategory,otherIncomeCategory,salaryRowCount);
}

@override
String toString() {
    return 'CsvCategoryEntry(csvValue: $csvValue, rowCount: $rowCount, resolution: $resolution, category: $category, salaryCategory: $salaryCategory, otherIncomeCategory: $otherIncomeCategory, salaryRowCount: $salaryRowCount)';
}


}

/// @nodoc
abstract mixin class _$CsvCategoryEntryCopyWith<$Res> implements $CsvCategoryEntryCopyWith<$Res> {
  factory _$CsvCategoryEntryCopyWith(_CsvCategoryEntry value, $Res Function(_CsvCategoryEntry) _then) = __$CsvCategoryEntryCopyWithImpl;
@override @useResult
$Res call({
 String csvValue, int rowCount, CategoryResolution resolution, Category? category, Category? salaryCategory, Category? otherIncomeCategory, int salaryRowCount
});


@override $CategoryResolutionCopyWith<$Res> get resolution;@override $CategoryCopyWith<$Res>? get category;@override $CategoryCopyWith<$Res>? get salaryCategory;@override $CategoryCopyWith<$Res>? get otherIncomeCategory;

}
/// @nodoc
class __$CsvCategoryEntryCopyWithImpl<$Res>
    implements _$CsvCategoryEntryCopyWith<$Res> {
  __$CsvCategoryEntryCopyWithImpl(this._self, this._then);

  final _CsvCategoryEntry _self;
  final $Res Function(_CsvCategoryEntry) _then;

/// Create a copy of CsvCategoryEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? csvValue = null,Object? rowCount = null,Object? resolution = null,Object? category = freezed,Object? salaryCategory = freezed,Object? otherIncomeCategory = freezed,Object? salaryRowCount = null,}) {
  return _then(_CsvCategoryEntry(
csvValue: null == csvValue ? _self.csvValue : csvValue // ignore: cast_nullable_to_non_nullable
as String,rowCount: null == rowCount ? _self.rowCount : rowCount // ignore: cast_nullable_to_non_nullable
as int,resolution: null == resolution ? _self.resolution : resolution // ignore: cast_nullable_to_non_nullable
as CategoryResolution,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as Category?,salaryCategory: freezed == salaryCategory ? _self.salaryCategory : salaryCategory // ignore: cast_nullable_to_non_nullable
as Category?,otherIncomeCategory: freezed == otherIncomeCategory ? _self.otherIncomeCategory : otherIncomeCategory // ignore: cast_nullable_to_non_nullable
as Category?,salaryRowCount: null == salaryRowCount ? _self.salaryRowCount : salaryRowCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of CsvCategoryEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryResolutionCopyWith<$Res> get resolution {
  
  return $CategoryResolutionCopyWith<$Res>(_self.resolution, (value) {
    return _then(_self.copyWith(resolution: value));
  });
}/// Create a copy of CsvCategoryEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryCopyWith<$Res>? get category {
    if (_self.category == null) {
    return null;
  }

  return $CategoryCopyWith<$Res>(_self.category!, (value) {
    return _then(_self.copyWith(category: value));
  });
}/// Create a copy of CsvCategoryEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryCopyWith<$Res>? get salaryCategory {
    if (_self.salaryCategory == null) {
    return null;
  }

  return $CategoryCopyWith<$Res>(_self.salaryCategory!, (value) {
    return _then(_self.copyWith(salaryCategory: value));
  });
}/// Create a copy of CsvCategoryEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryCopyWith<$Res>? get otherIncomeCategory {
    if (_self.otherIncomeCategory == null) {
    return null;
  }

  return $CategoryCopyWith<$Res>(_self.otherIncomeCategory!, (value) {
    return _then(_self.copyWith(otherIncomeCategory: value));
  });
}
}

// dart format on
