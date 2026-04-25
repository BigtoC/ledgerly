// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'categories_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

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
  const CategoriesData({required final  List<CategoryRowView> expense, required final  List<CategoryRowView> income}): _expense = expense,_income = income;
  

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoriesData&&const DeepCollectionEquality().equals(other._expense, _expense)&&const DeepCollectionEquality().equals(other._income, _income));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_expense),const DeepCollectionEquality().hash(_income));

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
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error),stack);

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryRowView&&(identical(other.category, category) || other.category == category)&&(identical(other.affordance, affordance) || other.affordance == affordance));
}


@override
int get hashCode => Object.hash(runtimeType,category,affordance);

@override
String toString() {
  return 'CategoryRowView(category: $category, affordance: $affordance)';
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
  return _then(_self.copyWith(
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
int get hashCode => Object.hash(runtimeType,category,affordance);

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

// dart format on
