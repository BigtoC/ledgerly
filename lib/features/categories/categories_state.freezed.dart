// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'categories_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CategoriesState {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoriesState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'CategoriesState()';
}


}

/// @nodoc
class $CategoriesStateCopyWith<$Res>  {
$CategoriesStateCopyWith(CategoriesState _, $Res Function(CategoriesState) __);
}


/// Adds pattern-matching-related methods to [CategoriesState].
extension CategoriesStatePatterns on CategoriesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CategoriesLoading value)?  loading,TResult Function( CategoriesData value)?  data,TResult Function( CategoriesError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CategoriesLoading() when loading != null:
return loading(_that);case CategoriesData() when data != null:
return data(_that);case CategoriesError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CategoriesLoading value)  loading,required TResult Function( CategoriesData value)  data,required TResult Function( CategoriesError value)  error,}){
final _that = this;
switch (_that) {
case CategoriesLoading():
return loading(_that);case CategoriesData():
return data(_that);case CategoriesError():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CategoriesLoading value)?  loading,TResult? Function( CategoriesData value)?  data,TResult? Function( CategoriesError value)?  error,}){
final _that = this;
switch (_that) {
case CategoriesLoading() when loading != null:
return loading(_that);case CategoriesData() when data != null:
return data(_that);case CategoriesError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<CategoryRowView> expense,  List<CategoryRowView> income)?  data,TResult Function( Object error,  StackTrace stack)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CategoriesLoading() when loading != null:
return loading();case CategoriesData() when data != null:
return data(_that.expense,_that.income);case CategoriesError() when error != null:
return error(_that.error,_that.stack);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<CategoryRowView> expense,  List<CategoryRowView> income)  data,required TResult Function( Object error,  StackTrace stack)  error,}) {final _that = this;
switch (_that) {
case CategoriesLoading():
return loading();case CategoriesData():
return data(_that.expense,_that.income);case CategoriesError():
return error(_that.error,_that.stack);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<CategoryRowView> expense,  List<CategoryRowView> income)?  data,TResult? Function( Object error,  StackTrace stack)?  error,}) {final _that = this;
switch (_that) {
case CategoriesLoading() when loading != null:
return loading();case CategoriesData() when data != null:
return data(_that.expense,_that.income);case CategoriesError() when error != null:
return error(_that.error,_that.stack);case _:
  return null;

}
}

}

/// @nodoc


class CategoriesLoading implements CategoriesState {
  const CategoriesLoading();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoriesLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'CategoriesState.loading()';
}


}




/// @nodoc


class CategoriesData implements CategoriesState {
  const CategoriesData({required  List<CategoryRowView> expense, required  List<CategoryRowView> income}): _expense = expense,_income = income;
  

 final  List<CategoryRowView> _expense;
 List<CategoryRowView> get expense {
  if (_expense is EqualUnmodifiableListView) return _expense;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_expense);
}

 final  List<CategoryRowView> _income;
 List<CategoryRowView> get income {
  if (_income is EqualUnmodifiableListView) return _income;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_income);
}


/// Create a copy of CategoriesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoriesDataCopyWith<CategoriesData> get copyWith => _$CategoriesDataCopyWithImpl<CategoriesData>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoriesData&&const DeepCollectionEquality().equals(other.expense, _expense)&&const DeepCollectionEquality().equals(other.income, _income));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_expense),const DeepCollectionEquality().hash(_income));
}

@override
String toString() {
    return 'CategoriesState.data(expense: $expense, income: $income)';
}


}

/// @nodoc
abstract mixin class $CategoriesDataCopyWith<$Res> implements $CategoriesStateCopyWith<$Res> {
  factory $CategoriesDataCopyWith(CategoriesData value, $Res Function(CategoriesData) _then) = _$CategoriesDataCopyWithImpl;
@useResult
$Res call({
 List<CategoryRowView> expense, List<CategoryRowView> income
});




}
/// @nodoc
class _$CategoriesDataCopyWithImpl<$Res>
    implements $CategoriesDataCopyWith<$Res> {
  _$CategoriesDataCopyWithImpl(this._self, this._then);

  final CategoriesData _self;
  final $Res Function(CategoriesData) _then;

/// Create a copy of CategoriesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? expense = null,Object? income = null,}) {
  return _then(CategoriesData(
expense: null == expense ? _self._expense : expense // ignore: cast_nullable_to_non_nullable
as List<CategoryRowView>,income: null == income ? _self._income : income // ignore: cast_nullable_to_non_nullable
as List<CategoryRowView>,
  ));
}


}

/// @nodoc


class CategoriesError implements CategoriesState {
  const CategoriesError(this.error, this.stack);
  

 final  Object error;
 final  StackTrace stack;

/// Create a copy of CategoriesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoriesErrorCopyWith<CategoriesError> get copyWith => _$CategoriesErrorCopyWithImpl<CategoriesError>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoriesError&&const DeepCollectionEquality().equals(other.error, error)&&(identical(other.stack, stack) || other.stack == stack));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(error),stack);
}

@override
String toString() {
    return 'CategoriesState.error(error: $error, stack: $stack)';
}


}

/// @nodoc
abstract mixin class $CategoriesErrorCopyWith<$Res> implements $CategoriesStateCopyWith<$Res> {
  factory $CategoriesErrorCopyWith(CategoriesError value, $Res Function(CategoriesError) _then) = _$CategoriesErrorCopyWithImpl;
@useResult
$Res call({
 Object error, StackTrace stack
});




}
/// @nodoc
class _$CategoriesErrorCopyWithImpl<$Res>
    implements $CategoriesErrorCopyWith<$Res> {
  _$CategoriesErrorCopyWithImpl(this._self, this._then);

  final CategoriesError _self;
  final $Res Function(CategoriesError) _then;

/// Create a copy of CategoriesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,Object? stack = null,}) {
  return _then(CategoriesError(
null == error ? _self.error : error ,null == stack ? _self.stack : stack // ignore: cast_nullable_to_non_nullable
as StackTrace,
  ));
}


}

/// @nodoc
mixin _$CategoryRowView {

 Category get category; CategoryRowAffordance get affordance;
/// Create a copy of CategoryRowView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryRowViewCopyWith<CategoryRowView> get copyWith => _$CategoryRowViewCopyWithImpl<CategoryRowView>(this as CategoryRowView, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CategoryRowView;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryRowView&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.affordance, _this.affordance) || other.affordance == _this.affordance));
}


@override
int get hashCode {
  final _this = this as CategoryRowView;
  return Object.hash(runtimeType,_this.category,_this.affordance);
}

@override
String toString() {
  final _this = this as CategoryRowView;
  return 'CategoryRowView(category: ${_this.category}, affordance: ${_this.affordance})';
}


}

/// @nodoc
abstract mixin class $CategoryRowViewCopyWith<$Res>  {
  factory $CategoryRowViewCopyWith(CategoryRowView value, $Res Function(CategoryRowView) _then) = _$CategoryRowViewCopyWithImpl;
@useResult
$Res call({
 Category category, CategoryRowAffordance affordance
});


$CategoryCopyWith<$Res> get category;

}
/// @nodoc
class _$CategoryRowViewCopyWithImpl<$Res>
    implements $CategoryRowViewCopyWith<$Res> {
  _$CategoryRowViewCopyWithImpl(this._self, this._then);

  final CategoryRowView _self;
  final $Res Function(CategoryRowView) _then;

/// Create a copy of CategoryRowView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? category = null,Object? affordance = null,}) {
  return _then(CategoryRowView(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as Category,affordance: null == affordance ? _self.affordance : affordance // ignore: cast_nullable_to_non_nullable
as CategoryRowAffordance,
  ));
}
/// Create a copy of CategoryRowView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryCopyWith<$Res> get category {
  
  return $CategoryCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}


/// Adds pattern-matching-related methods to [CategoryRowView].
extension CategoryRowViewPatterns on CategoryRowView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategoryRowView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategoryRowView() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategoryRowView value)  $default,){
final _that = this;
switch (_that) {
case _CategoryRowView():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategoryRowView value)?  $default,){
final _that = this;
switch (_that) {
case _CategoryRowView() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Category category,  CategoryRowAffordance affordance)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategoryRowView() when $default != null:
return $default(_that.category,_that.affordance);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Category category,  CategoryRowAffordance affordance)  $default,) {final _that = this;
switch (_that) {
case _CategoryRowView():
return $default(_that.category,_that.affordance);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Category category,  CategoryRowAffordance affordance)?  $default,) {final _that = this;
switch (_that) {
case _CategoryRowView() when $default != null:
return $default(_that.category,_that.affordance);case _:
  return null;

}
}

}

/// @nodoc


class _CategoryRowView implements CategoryRowView {
  const _CategoryRowView({required this.category, required this.affordance});
  

@override final  Category category;
@override final  CategoryRowAffordance affordance;

/// Create a copy of CategoryRowView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryRowViewCopyWith<_CategoryRowView> get copyWith => __$CategoryRowViewCopyWithImpl<_CategoryRowView>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategoryRowView&&(identical(other.category, category) || other.category == category)&&(identical(other.affordance, affordance) || other.affordance == affordance));
}


@override
int get hashCode {
    return Object.hash(runtimeType,category,affordance);
}

@override
String toString() {
    return 'CategoryRowView(category: $category, affordance: $affordance)';
}


}

/// @nodoc
abstract mixin class _$CategoryRowViewCopyWith<$Res> implements $CategoryRowViewCopyWith<$Res> {
  factory _$CategoryRowViewCopyWith(_CategoryRowView value, $Res Function(_CategoryRowView) _then) = __$CategoryRowViewCopyWithImpl;
@override @useResult
$Res call({
 Category category, CategoryRowAffordance affordance
});


@override $CategoryCopyWith<$Res> get category;

}
/// @nodoc
class __$CategoryRowViewCopyWithImpl<$Res>
    implements _$CategoryRowViewCopyWith<$Res> {
  __$CategoryRowViewCopyWithImpl(this._self, this._then);

  final _CategoryRowView _self;
  final $Res Function(_CategoryRowView) _then;

/// Create a copy of CategoryRowView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? category = null,Object? affordance = null,}) {
  return _then(_CategoryRowView(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as Category,affordance: null == affordance ? _self.affordance : affordance // ignore: cast_nullable_to_non_nullable
as CategoryRowAffordance,
  ));
}

/// Create a copy of CategoryRowView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryCopyWith<$Res> get category {
  
  return $CategoryCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}

/// @nodoc
mixin _$SaveCategoryOutcome {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveCategoryOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SaveCategoryOutcome()';
}


}

/// @nodoc
class $SaveCategoryOutcomeCopyWith<$Res>  {
$SaveCategoryOutcomeCopyWith(SaveCategoryOutcome _, $Res Function(SaveCategoryOutcome) __);
}


/// Adds pattern-matching-related methods to [SaveCategoryOutcome].
extension SaveCategoryOutcomePatterns on SaveCategoryOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SaveCategoryOk value)?  ok,TResult Function( SaveCategoryFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SaveCategoryOk() when ok != null:
return ok(_that);case SaveCategoryFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SaveCategoryOk value)  ok,required TResult Function( SaveCategoryFailed value)  failed,}){
final _that = this;
switch (_that) {
case SaveCategoryOk():
return ok(_that);case SaveCategoryFailed():
return failed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SaveCategoryOk value)?  ok,TResult? Function( SaveCategoryFailed value)?  failed,}){
final _that = this;
switch (_that) {
case SaveCategoryOk() when ok != null:
return ok(_that);case SaveCategoryFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  ok,TResult Function()?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SaveCategoryOk() when ok != null:
return ok();case SaveCategoryFailed() when failed != null:
return failed();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  ok,required TResult Function()  failed,}) {final _that = this;
switch (_that) {
case SaveCategoryOk():
return ok();case SaveCategoryFailed():
return failed();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  ok,TResult? Function()?  failed,}) {final _that = this;
switch (_that) {
case SaveCategoryOk() when ok != null:
return ok();case SaveCategoryFailed() when failed != null:
return failed();case _:
  return null;

}
}

}

/// @nodoc


class SaveCategoryOk implements SaveCategoryOutcome {
  const SaveCategoryOk();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveCategoryOk);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SaveCategoryOutcome.ok()';
}


}




/// @nodoc


class SaveCategoryFailed implements SaveCategoryOutcome {
  const SaveCategoryFailed();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveCategoryFailed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SaveCategoryOutcome.failed()';
}


}




/// @nodoc
mixin _$ArchiveCategoryOutcome {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ArchiveCategoryOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ArchiveCategoryOutcome()';
}


}

/// @nodoc
class $ArchiveCategoryOutcomeCopyWith<$Res>  {
$ArchiveCategoryOutcomeCopyWith(ArchiveCategoryOutcome _, $Res Function(ArchiveCategoryOutcome) __);
}


/// Adds pattern-matching-related methods to [ArchiveCategoryOutcome].
extension ArchiveCategoryOutcomePatterns on ArchiveCategoryOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ArchiveCategoryOk value)?  ok,TResult Function( ArchiveCategoryHasActiveRecurringRule value)?  hasActiveRecurringRule,TResult Function( ArchiveCategoryFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ArchiveCategoryOk() when ok != null:
return ok(_that);case ArchiveCategoryHasActiveRecurringRule() when hasActiveRecurringRule != null:
return hasActiveRecurringRule(_that);case ArchiveCategoryFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ArchiveCategoryOk value)  ok,required TResult Function( ArchiveCategoryHasActiveRecurringRule value)  hasActiveRecurringRule,required TResult Function( ArchiveCategoryFailed value)  failed,}){
final _that = this;
switch (_that) {
case ArchiveCategoryOk():
return ok(_that);case ArchiveCategoryHasActiveRecurringRule():
return hasActiveRecurringRule(_that);case ArchiveCategoryFailed():
return failed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ArchiveCategoryOk value)?  ok,TResult? Function( ArchiveCategoryHasActiveRecurringRule value)?  hasActiveRecurringRule,TResult? Function( ArchiveCategoryFailed value)?  failed,}){
final _that = this;
switch (_that) {
case ArchiveCategoryOk() when ok != null:
return ok(_that);case ArchiveCategoryHasActiveRecurringRule() when hasActiveRecurringRule != null:
return hasActiveRecurringRule(_that);case ArchiveCategoryFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  ok,TResult Function()?  hasActiveRecurringRule,TResult Function()?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ArchiveCategoryOk() when ok != null:
return ok();case ArchiveCategoryHasActiveRecurringRule() when hasActiveRecurringRule != null:
return hasActiveRecurringRule();case ArchiveCategoryFailed() when failed != null:
return failed();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  ok,required TResult Function()  hasActiveRecurringRule,required TResult Function()  failed,}) {final _that = this;
switch (_that) {
case ArchiveCategoryOk():
return ok();case ArchiveCategoryHasActiveRecurringRule():
return hasActiveRecurringRule();case ArchiveCategoryFailed():
return failed();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  ok,TResult? Function()?  hasActiveRecurringRule,TResult? Function()?  failed,}) {final _that = this;
switch (_that) {
case ArchiveCategoryOk() when ok != null:
return ok();case ArchiveCategoryHasActiveRecurringRule() when hasActiveRecurringRule != null:
return hasActiveRecurringRule();case ArchiveCategoryFailed() when failed != null:
return failed();case _:
  return null;

}
}

}

/// @nodoc


class ArchiveCategoryOk implements ArchiveCategoryOutcome {
  const ArchiveCategoryOk();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ArchiveCategoryOk);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ArchiveCategoryOutcome.ok()';
}


}




/// @nodoc


class ArchiveCategoryHasActiveRecurringRule implements ArchiveCategoryOutcome {
  const ArchiveCategoryHasActiveRecurringRule();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ArchiveCategoryHasActiveRecurringRule);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ArchiveCategoryOutcome.hasActiveRecurringRule()';
}


}




/// @nodoc


class ArchiveCategoryFailed implements ArchiveCategoryOutcome {
  const ArchiveCategoryFailed();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ArchiveCategoryFailed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ArchiveCategoryOutcome.failed()';
}


}




/// @nodoc
mixin _$UndoArchiveCategoryOutcome {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is UndoArchiveCategoryOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'UndoArchiveCategoryOutcome()';
}


}

/// @nodoc
class $UndoArchiveCategoryOutcomeCopyWith<$Res>  {
$UndoArchiveCategoryOutcomeCopyWith(UndoArchiveCategoryOutcome _, $Res Function(UndoArchiveCategoryOutcome) __);
}


/// Adds pattern-matching-related methods to [UndoArchiveCategoryOutcome].
extension UndoArchiveCategoryOutcomePatterns on UndoArchiveCategoryOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( UndoArchiveCategoryOk value)?  ok,TResult Function( UndoArchiveCategoryFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case UndoArchiveCategoryOk() when ok != null:
return ok(_that);case UndoArchiveCategoryFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( UndoArchiveCategoryOk value)  ok,required TResult Function( UndoArchiveCategoryFailed value)  failed,}){
final _that = this;
switch (_that) {
case UndoArchiveCategoryOk():
return ok(_that);case UndoArchiveCategoryFailed():
return failed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( UndoArchiveCategoryOk value)?  ok,TResult? Function( UndoArchiveCategoryFailed value)?  failed,}){
final _that = this;
switch (_that) {
case UndoArchiveCategoryOk() when ok != null:
return ok(_that);case UndoArchiveCategoryFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  ok,TResult Function()?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case UndoArchiveCategoryOk() when ok != null:
return ok();case UndoArchiveCategoryFailed() when failed != null:
return failed();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  ok,required TResult Function()  failed,}) {final _that = this;
switch (_that) {
case UndoArchiveCategoryOk():
return ok();case UndoArchiveCategoryFailed():
return failed();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  ok,TResult? Function()?  failed,}) {final _that = this;
switch (_that) {
case UndoArchiveCategoryOk() when ok != null:
return ok();case UndoArchiveCategoryFailed() when failed != null:
return failed();case _:
  return null;

}
}

}

/// @nodoc


class UndoArchiveCategoryOk implements UndoArchiveCategoryOutcome {
  const UndoArchiveCategoryOk();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is UndoArchiveCategoryOk);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'UndoArchiveCategoryOutcome.ok()';
}


}




/// @nodoc


class UndoArchiveCategoryFailed implements UndoArchiveCategoryOutcome {
  const UndoArchiveCategoryFailed();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is UndoArchiveCategoryFailed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'UndoArchiveCategoryOutcome.failed()';
}


}




/// @nodoc
mixin _$DeleteCategoryOutcome {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteCategoryOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'DeleteCategoryOutcome()';
}


}

/// @nodoc
class $DeleteCategoryOutcomeCopyWith<$Res>  {
$DeleteCategoryOutcomeCopyWith(DeleteCategoryOutcome _, $Res Function(DeleteCategoryOutcome) __);
}


/// Adds pattern-matching-related methods to [DeleteCategoryOutcome].
extension DeleteCategoryOutcomePatterns on DeleteCategoryOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DeleteCategoryOk value)?  ok,TResult Function( DeleteCategoryInUse value)?  inUse,TResult Function( DeleteCategoryFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DeleteCategoryOk() when ok != null:
return ok(_that);case DeleteCategoryInUse() when inUse != null:
return inUse(_that);case DeleteCategoryFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DeleteCategoryOk value)  ok,required TResult Function( DeleteCategoryInUse value)  inUse,required TResult Function( DeleteCategoryFailed value)  failed,}){
final _that = this;
switch (_that) {
case DeleteCategoryOk():
return ok(_that);case DeleteCategoryInUse():
return inUse(_that);case DeleteCategoryFailed():
return failed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DeleteCategoryOk value)?  ok,TResult? Function( DeleteCategoryInUse value)?  inUse,TResult? Function( DeleteCategoryFailed value)?  failed,}){
final _that = this;
switch (_that) {
case DeleteCategoryOk() when ok != null:
return ok(_that);case DeleteCategoryInUse() when inUse != null:
return inUse(_that);case DeleteCategoryFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  ok,TResult Function()?  inUse,TResult Function()?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DeleteCategoryOk() when ok != null:
return ok();case DeleteCategoryInUse() when inUse != null:
return inUse();case DeleteCategoryFailed() when failed != null:
return failed();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  ok,required TResult Function()  inUse,required TResult Function()  failed,}) {final _that = this;
switch (_that) {
case DeleteCategoryOk():
return ok();case DeleteCategoryInUse():
return inUse();case DeleteCategoryFailed():
return failed();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  ok,TResult? Function()?  inUse,TResult? Function()?  failed,}) {final _that = this;
switch (_that) {
case DeleteCategoryOk() when ok != null:
return ok();case DeleteCategoryInUse() when inUse != null:
return inUse();case DeleteCategoryFailed() when failed != null:
return failed();case _:
  return null;

}
}

}

/// @nodoc


class DeleteCategoryOk implements DeleteCategoryOutcome {
  const DeleteCategoryOk();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteCategoryOk);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'DeleteCategoryOutcome.ok()';
}


}




/// @nodoc


class DeleteCategoryInUse implements DeleteCategoryOutcome {
  const DeleteCategoryInUse();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteCategoryInUse);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'DeleteCategoryOutcome.inUse()';
}


}




/// @nodoc


class DeleteCategoryFailed implements DeleteCategoryOutcome {
  const DeleteCategoryFailed();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteCategoryFailed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'DeleteCategoryOutcome.failed()';
}


}




/// @nodoc
mixin _$ReorderCategoriesOutcome {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ReorderCategoriesOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ReorderCategoriesOutcome()';
}


}

/// @nodoc
class $ReorderCategoriesOutcomeCopyWith<$Res>  {
$ReorderCategoriesOutcomeCopyWith(ReorderCategoriesOutcome _, $Res Function(ReorderCategoriesOutcome) __);
}


/// Adds pattern-matching-related methods to [ReorderCategoriesOutcome].
extension ReorderCategoriesOutcomePatterns on ReorderCategoriesOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ReorderCategoriesOk value)?  ok,TResult Function( ReorderCategoriesFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ReorderCategoriesOk() when ok != null:
return ok(_that);case ReorderCategoriesFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ReorderCategoriesOk value)  ok,required TResult Function( ReorderCategoriesFailed value)  failed,}){
final _that = this;
switch (_that) {
case ReorderCategoriesOk():
return ok(_that);case ReorderCategoriesFailed():
return failed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ReorderCategoriesOk value)?  ok,TResult? Function( ReorderCategoriesFailed value)?  failed,}){
final _that = this;
switch (_that) {
case ReorderCategoriesOk() when ok != null:
return ok(_that);case ReorderCategoriesFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  ok,TResult Function()?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ReorderCategoriesOk() when ok != null:
return ok();case ReorderCategoriesFailed() when failed != null:
return failed();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  ok,required TResult Function()  failed,}) {final _that = this;
switch (_that) {
case ReorderCategoriesOk():
return ok();case ReorderCategoriesFailed():
return failed();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  ok,TResult? Function()?  failed,}) {final _that = this;
switch (_that) {
case ReorderCategoriesOk() when ok != null:
return ok();case ReorderCategoriesFailed() when failed != null:
return failed();case _:
  return null;

}
}

}

/// @nodoc


class ReorderCategoriesOk implements ReorderCategoriesOutcome {
  const ReorderCategoriesOk();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ReorderCategoriesOk);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ReorderCategoriesOutcome.ok()';
}


}




/// @nodoc


class ReorderCategoriesFailed implements ReorderCategoriesOutcome {
  const ReorderCategoriesFailed();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ReorderCategoriesFailed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ReorderCategoriesOutcome.failed()';
}


}




// dart format on
