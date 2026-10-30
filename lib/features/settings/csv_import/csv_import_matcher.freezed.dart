// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'csv_import_matcher.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CsvAccountMatch {

 String get csvValue; int get rowCount; CsvAccountTier get tier;/// The initial resolution; null when the user must decide.
 AccountResolution? get resolution;/// The account type the value names (tiers 2, 2b, 2c); null otherwise.
 AccountType? get matchedType;/// Currency of an account created for this value: the most frequent
/// among its rows, a tie going to the default currency, then to the
/// alphabetically first code.
 String get currencyCode;/// "Use an existing account" choices: every active account, then any
/// archived account whose name normalizes to the value.
 List<Account> get options;
/// Create a copy of CsvAccountMatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CsvAccountMatchCopyWith<CsvAccountMatch> get copyWith => _$CsvAccountMatchCopyWithImpl<CsvAccountMatch>(this as CsvAccountMatch, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CsvAccountMatch;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CsvAccountMatch&&(identical(other.csvValue, _this.csvValue) || other.csvValue == _this.csvValue)&&(identical(other.rowCount, _this.rowCount) || other.rowCount == _this.rowCount)&&(identical(other.tier, _this.tier) || other.tier == _this.tier)&&(identical(other.resolution, _this.resolution) || other.resolution == _this.resolution)&&(identical(other.matchedType, _this.matchedType) || other.matchedType == _this.matchedType)&&(identical(other.currencyCode, _this.currencyCode) || other.currencyCode == _this.currencyCode)&&const DeepCollectionEquality().equals(other.options, _this.options));
}


@override
int get hashCode {
  final _this = this as CsvAccountMatch;
  return Object.hash(runtimeType,_this.csvValue,_this.rowCount,_this.tier,_this.resolution,_this.matchedType,_this.currencyCode,const DeepCollectionEquality().hash(_this.options));
}

@override
String toString() {
  final _this = this as CsvAccountMatch;
  return 'CsvAccountMatch(csvValue: ${_this.csvValue}, rowCount: ${_this.rowCount}, tier: ${_this.tier}, resolution: ${_this.resolution}, matchedType: ${_this.matchedType}, currencyCode: ${_this.currencyCode}, options: ${_this.options})';
}


}

/// @nodoc
abstract mixin class $CsvAccountMatchCopyWith<$Res>  {
  factory $CsvAccountMatchCopyWith(CsvAccountMatch value, $Res Function(CsvAccountMatch) _then) = _$CsvAccountMatchCopyWithImpl;
@useResult
$Res call({
 String csvValue, int rowCount, CsvAccountTier tier, AccountResolution? resolution, AccountType? matchedType, String currencyCode, List<Account> options
});


$AccountResolutionCopyWith<$Res>? get resolution;$AccountTypeCopyWith<$Res>? get matchedType;

}
/// @nodoc
class _$CsvAccountMatchCopyWithImpl<$Res>
    implements $CsvAccountMatchCopyWith<$Res> {
  _$CsvAccountMatchCopyWithImpl(this._self, this._then);

  final CsvAccountMatch _self;
  final $Res Function(CsvAccountMatch) _then;

/// Create a copy of CsvAccountMatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? csvValue = null,Object? rowCount = null,Object? tier = null,Object? resolution = freezed,Object? matchedType = freezed,Object? currencyCode = null,Object? options = null,}) {
  return _then(CsvAccountMatch(
csvValue: null == csvValue ? _self.csvValue : csvValue // ignore: cast_nullable_to_non_nullable
as String,rowCount: null == rowCount ? _self.rowCount : rowCount // ignore: cast_nullable_to_non_nullable
as int,tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as CsvAccountTier,resolution: freezed == resolution ? _self.resolution : resolution // ignore: cast_nullable_to_non_nullable
as AccountResolution?,matchedType: freezed == matchedType ? _self.matchedType : matchedType // ignore: cast_nullable_to_non_nullable
as AccountType?,currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as List<Account>,
  ));
}
/// Create a copy of CsvAccountMatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AccountResolutionCopyWith<$Res>? get resolution {
    if (_self.resolution == null) {
    return null;
  }

  return $AccountResolutionCopyWith<$Res>(_self.resolution!, (value) {
    return _then(_self.copyWith(resolution: value));
  });
}/// Create a copy of CsvAccountMatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AccountTypeCopyWith<$Res>? get matchedType {
    if (_self.matchedType == null) {
    return null;
  }

  return $AccountTypeCopyWith<$Res>(_self.matchedType!, (value) {
    return _then(_self.copyWith(matchedType: value));
  });
}
}


/// Adds pattern-matching-related methods to [CsvAccountMatch].
extension CsvAccountMatchPatterns on CsvAccountMatch {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CsvAccountMatch value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CsvAccountMatch() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CsvAccountMatch value)  $default,){
final _that = this;
switch (_that) {
case _CsvAccountMatch():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CsvAccountMatch value)?  $default,){
final _that = this;
switch (_that) {
case _CsvAccountMatch() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String csvValue,  int rowCount,  CsvAccountTier tier,  AccountResolution? resolution,  AccountType? matchedType,  String currencyCode,  List<Account> options)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CsvAccountMatch() when $default != null:
return $default(_that.csvValue,_that.rowCount,_that.tier,_that.resolution,_that.matchedType,_that.currencyCode,_that.options);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String csvValue,  int rowCount,  CsvAccountTier tier,  AccountResolution? resolution,  AccountType? matchedType,  String currencyCode,  List<Account> options)  $default,) {final _that = this;
switch (_that) {
case _CsvAccountMatch():
return $default(_that.csvValue,_that.rowCount,_that.tier,_that.resolution,_that.matchedType,_that.currencyCode,_that.options);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String csvValue,  int rowCount,  CsvAccountTier tier,  AccountResolution? resolution,  AccountType? matchedType,  String currencyCode,  List<Account> options)?  $default,) {final _that = this;
switch (_that) {
case _CsvAccountMatch() when $default != null:
return $default(_that.csvValue,_that.rowCount,_that.tier,_that.resolution,_that.matchedType,_that.currencyCode,_that.options);case _:
  return null;

}
}

}

/// @nodoc


class _CsvAccountMatch extends CsvAccountMatch {
  const _CsvAccountMatch({required this.csvValue, required this.rowCount, required this.tier, this.resolution, this.matchedType, required this.currencyCode, required  List<Account> options}): _options = options,super._();
  

@override final  String csvValue;
@override final  int rowCount;
@override final  CsvAccountTier tier;
/// The initial resolution; null when the user must decide.
@override final  AccountResolution? resolution;
/// The account type the value names (tiers 2, 2b, 2c); null otherwise.
@override final  AccountType? matchedType;
/// Currency of an account created for this value: the most frequent
/// among its rows, a tie going to the default currency, then to the
/// alphabetically first code.
@override final  String currencyCode;
/// "Use an existing account" choices: every active account, then any
/// archived account whose name normalizes to the value.
 final  List<Account> _options;
/// "Use an existing account" choices: every active account, then any
/// archived account whose name normalizes to the value.
@override List<Account> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}


/// Create a copy of CsvAccountMatch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CsvAccountMatchCopyWith<_CsvAccountMatch> get copyWith => __$CsvAccountMatchCopyWithImpl<_CsvAccountMatch>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CsvAccountMatch&&(identical(other.csvValue, csvValue) || other.csvValue == csvValue)&&(identical(other.rowCount, rowCount) || other.rowCount == rowCount)&&(identical(other.tier, tier) || other.tier == tier)&&(identical(other.resolution, resolution) || other.resolution == resolution)&&(identical(other.matchedType, matchedType) || other.matchedType == matchedType)&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode)&&const DeepCollectionEquality().equals(other.options, _options));
}


@override
int get hashCode {
    return Object.hash(runtimeType,csvValue,rowCount,tier,resolution,matchedType,currencyCode,const DeepCollectionEquality().hash(_options));
}

@override
String toString() {
    return 'CsvAccountMatch(csvValue: $csvValue, rowCount: $rowCount, tier: $tier, resolution: $resolution, matchedType: $matchedType, currencyCode: $currencyCode, options: $options)';
}


}

/// @nodoc
abstract mixin class _$CsvAccountMatchCopyWith<$Res> implements $CsvAccountMatchCopyWith<$Res> {
  factory _$CsvAccountMatchCopyWith(_CsvAccountMatch value, $Res Function(_CsvAccountMatch) _then) = __$CsvAccountMatchCopyWithImpl;
@override @useResult
$Res call({
 String csvValue, int rowCount, CsvAccountTier tier, AccountResolution? resolution, AccountType? matchedType, String currencyCode, List<Account> options
});


@override $AccountResolutionCopyWith<$Res>? get resolution;@override $AccountTypeCopyWith<$Res>? get matchedType;

}
/// @nodoc
class __$CsvAccountMatchCopyWithImpl<$Res>
    implements _$CsvAccountMatchCopyWith<$Res> {
  __$CsvAccountMatchCopyWithImpl(this._self, this._then);

  final _CsvAccountMatch _self;
  final $Res Function(_CsvAccountMatch) _then;

/// Create a copy of CsvAccountMatch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? csvValue = null,Object? rowCount = null,Object? tier = null,Object? resolution = freezed,Object? matchedType = freezed,Object? currencyCode = null,Object? options = null,}) {
  return _then(_CsvAccountMatch(
csvValue: null == csvValue ? _self.csvValue : csvValue // ignore: cast_nullable_to_non_nullable
as String,rowCount: null == rowCount ? _self.rowCount : rowCount // ignore: cast_nullable_to_non_nullable
as int,tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as CsvAccountTier,resolution: freezed == resolution ? _self.resolution : resolution // ignore: cast_nullable_to_non_nullable
as AccountResolution?,matchedType: freezed == matchedType ? _self.matchedType : matchedType // ignore: cast_nullable_to_non_nullable
as AccountType?,currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<Account>,
  ));
}

/// Create a copy of CsvAccountMatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AccountResolutionCopyWith<$Res>? get resolution {
    if (_self.resolution == null) {
    return null;
  }

  return $AccountResolutionCopyWith<$Res>(_self.resolution!, (value) {
    return _then(_self.copyWith(resolution: value));
  });
}/// Create a copy of CsvAccountMatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AccountTypeCopyWith<$Res>? get matchedType {
    if (_self.matchedType == null) {
    return null;
  }

  return $AccountTypeCopyWith<$Res>(_self.matchedType!, (value) {
    return _then(_self.copyWith(matchedType: value));
  });
}
}

/// @nodoc
mixin _$CsvCategoryMatch {

 String get csvValue; int get rowCount; CategoryResolution get resolution;/// For the income marker, how many rows have a Salary note; the
/// other `rowCount - salaryRowCount` go to Other income. 0 otherwise.
 int get salaryRowCount;
/// Create a copy of CsvCategoryMatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CsvCategoryMatchCopyWith<CsvCategoryMatch> get copyWith => _$CsvCategoryMatchCopyWithImpl<CsvCategoryMatch>(this as CsvCategoryMatch, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CsvCategoryMatch;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CsvCategoryMatch&&(identical(other.csvValue, _this.csvValue) || other.csvValue == _this.csvValue)&&(identical(other.rowCount, _this.rowCount) || other.rowCount == _this.rowCount)&&(identical(other.resolution, _this.resolution) || other.resolution == _this.resolution)&&(identical(other.salaryRowCount, _this.salaryRowCount) || other.salaryRowCount == _this.salaryRowCount));
}


@override
int get hashCode {
  final _this = this as CsvCategoryMatch;
  return Object.hash(runtimeType,_this.csvValue,_this.rowCount,_this.resolution,_this.salaryRowCount);
}

@override
String toString() {
  final _this = this as CsvCategoryMatch;
  return 'CsvCategoryMatch(csvValue: ${_this.csvValue}, rowCount: ${_this.rowCount}, resolution: ${_this.resolution}, salaryRowCount: ${_this.salaryRowCount})';
}


}

/// @nodoc
abstract mixin class $CsvCategoryMatchCopyWith<$Res>  {
  factory $CsvCategoryMatchCopyWith(CsvCategoryMatch value, $Res Function(CsvCategoryMatch) _then) = _$CsvCategoryMatchCopyWithImpl;
@useResult
$Res call({
 String csvValue, int rowCount, CategoryResolution resolution, int salaryRowCount
});


$CategoryResolutionCopyWith<$Res> get resolution;

}
/// @nodoc
class _$CsvCategoryMatchCopyWithImpl<$Res>
    implements $CsvCategoryMatchCopyWith<$Res> {
  _$CsvCategoryMatchCopyWithImpl(this._self, this._then);

  final CsvCategoryMatch _self;
  final $Res Function(CsvCategoryMatch) _then;

/// Create a copy of CsvCategoryMatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? csvValue = null,Object? rowCount = null,Object? resolution = null,Object? salaryRowCount = null,}) {
  return _then(CsvCategoryMatch(
csvValue: null == csvValue ? _self.csvValue : csvValue // ignore: cast_nullable_to_non_nullable
as String,rowCount: null == rowCount ? _self.rowCount : rowCount // ignore: cast_nullable_to_non_nullable
as int,resolution: null == resolution ? _self.resolution : resolution // ignore: cast_nullable_to_non_nullable
as CategoryResolution,salaryRowCount: null == salaryRowCount ? _self.salaryRowCount : salaryRowCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of CsvCategoryMatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryResolutionCopyWith<$Res> get resolution {
  
  return $CategoryResolutionCopyWith<$Res>(_self.resolution, (value) {
    return _then(_self.copyWith(resolution: value));
  });
}
}


/// Adds pattern-matching-related methods to [CsvCategoryMatch].
extension CsvCategoryMatchPatterns on CsvCategoryMatch {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CsvCategoryMatch value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CsvCategoryMatch() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CsvCategoryMatch value)  $default,){
final _that = this;
switch (_that) {
case _CsvCategoryMatch():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CsvCategoryMatch value)?  $default,){
final _that = this;
switch (_that) {
case _CsvCategoryMatch() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String csvValue,  int rowCount,  CategoryResolution resolution,  int salaryRowCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CsvCategoryMatch() when $default != null:
return $default(_that.csvValue,_that.rowCount,_that.resolution,_that.salaryRowCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String csvValue,  int rowCount,  CategoryResolution resolution,  int salaryRowCount)  $default,) {final _that = this;
switch (_that) {
case _CsvCategoryMatch():
return $default(_that.csvValue,_that.rowCount,_that.resolution,_that.salaryRowCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String csvValue,  int rowCount,  CategoryResolution resolution,  int salaryRowCount)?  $default,) {final _that = this;
switch (_that) {
case _CsvCategoryMatch() when $default != null:
return $default(_that.csvValue,_that.rowCount,_that.resolution,_that.salaryRowCount);case _:
  return null;

}
}

}

/// @nodoc


class _CsvCategoryMatch extends CsvCategoryMatch {
  const _CsvCategoryMatch({required this.csvValue, required this.rowCount, required this.resolution, this.salaryRowCount = 0}): super._();
  

@override final  String csvValue;
@override final  int rowCount;
@override final  CategoryResolution resolution;
/// For the income marker, how many rows have a Salary note; the
/// other `rowCount - salaryRowCount` go to Other income. 0 otherwise.
@override@JsonKey() final  int salaryRowCount;

/// Create a copy of CsvCategoryMatch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CsvCategoryMatchCopyWith<_CsvCategoryMatch> get copyWith => __$CsvCategoryMatchCopyWithImpl<_CsvCategoryMatch>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CsvCategoryMatch&&(identical(other.csvValue, csvValue) || other.csvValue == csvValue)&&(identical(other.rowCount, rowCount) || other.rowCount == rowCount)&&(identical(other.resolution, resolution) || other.resolution == resolution)&&(identical(other.salaryRowCount, salaryRowCount) || other.salaryRowCount == salaryRowCount));
}


@override
int get hashCode {
    return Object.hash(runtimeType,csvValue,rowCount,resolution,salaryRowCount);
}

@override
String toString() {
    return 'CsvCategoryMatch(csvValue: $csvValue, rowCount: $rowCount, resolution: $resolution, salaryRowCount: $salaryRowCount)';
}


}

/// @nodoc
abstract mixin class _$CsvCategoryMatchCopyWith<$Res> implements $CsvCategoryMatchCopyWith<$Res> {
  factory _$CsvCategoryMatchCopyWith(_CsvCategoryMatch value, $Res Function(_CsvCategoryMatch) _then) = __$CsvCategoryMatchCopyWithImpl;
@override @useResult
$Res call({
 String csvValue, int rowCount, CategoryResolution resolution, int salaryRowCount
});


@override $CategoryResolutionCopyWith<$Res> get resolution;

}
/// @nodoc
class __$CsvCategoryMatchCopyWithImpl<$Res>
    implements _$CsvCategoryMatchCopyWith<$Res> {
  __$CsvCategoryMatchCopyWithImpl(this._self, this._then);

  final _CsvCategoryMatch _self;
  final $Res Function(_CsvCategoryMatch) _then;

/// Create a copy of CsvCategoryMatch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? csvValue = null,Object? rowCount = null,Object? resolution = null,Object? salaryRowCount = null,}) {
  return _then(_CsvCategoryMatch(
csvValue: null == csvValue ? _self.csvValue : csvValue // ignore: cast_nullable_to_non_nullable
as String,rowCount: null == rowCount ? _self.rowCount : rowCount // ignore: cast_nullable_to_non_nullable
as int,resolution: null == resolution ? _self.resolution : resolution // ignore: cast_nullable_to_non_nullable
as CategoryResolution,salaryRowCount: null == salaryRowCount ? _self.salaryRowCount : salaryRowCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of CsvCategoryMatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryResolutionCopyWith<$Res> get resolution {
  
  return $CategoryResolutionCopyWith<$Res>(_self.resolution, (value) {
    return _then(_self.copyWith(resolution: value));
  });
}
}

/// @nodoc
mixin _$CsvImportMatch {

 List<CsvAccountMatch> get accounts; List<CsvCategoryMatch> get categories;/// The Salary label of every locale, for [CsvImportPlan.salaryNotes].
 Set<String> get salaryNotes;
/// Create a copy of CsvImportMatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CsvImportMatchCopyWith<CsvImportMatch> get copyWith => _$CsvImportMatchCopyWithImpl<CsvImportMatch>(this as CsvImportMatch, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CsvImportMatch;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CsvImportMatch&&const DeepCollectionEquality().equals(other.accounts, _this.accounts)&&const DeepCollectionEquality().equals(other.categories, _this.categories)&&const DeepCollectionEquality().equals(other.salaryNotes, _this.salaryNotes));
}


@override
int get hashCode {
  final _this = this as CsvImportMatch;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.accounts),const DeepCollectionEquality().hash(_this.categories),const DeepCollectionEquality().hash(_this.salaryNotes));
}

@override
String toString() {
  final _this = this as CsvImportMatch;
  return 'CsvImportMatch(accounts: ${_this.accounts}, categories: ${_this.categories}, salaryNotes: ${_this.salaryNotes})';
}


}

/// @nodoc
abstract mixin class $CsvImportMatchCopyWith<$Res>  {
  factory $CsvImportMatchCopyWith(CsvImportMatch value, $Res Function(CsvImportMatch) _then) = _$CsvImportMatchCopyWithImpl;
@useResult
$Res call({
 List<CsvAccountMatch> accounts, List<CsvCategoryMatch> categories, Set<String> salaryNotes
});




}
/// @nodoc
class _$CsvImportMatchCopyWithImpl<$Res>
    implements $CsvImportMatchCopyWith<$Res> {
  _$CsvImportMatchCopyWithImpl(this._self, this._then);

  final CsvImportMatch _self;
  final $Res Function(CsvImportMatch) _then;

/// Create a copy of CsvImportMatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accounts = null,Object? categories = null,Object? salaryNotes = null,}) {
  return _then(CsvImportMatch(
accounts: null == accounts ? _self.accounts : accounts // ignore: cast_nullable_to_non_nullable
as List<CsvAccountMatch>,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<CsvCategoryMatch>,salaryNotes: null == salaryNotes ? _self.salaryNotes : salaryNotes // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [CsvImportMatch].
extension CsvImportMatchPatterns on CsvImportMatch {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CsvImportMatch value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CsvImportMatch() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CsvImportMatch value)  $default,){
final _that = this;
switch (_that) {
case _CsvImportMatch():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CsvImportMatch value)?  $default,){
final _that = this;
switch (_that) {
case _CsvImportMatch() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<CsvAccountMatch> accounts,  List<CsvCategoryMatch> categories,  Set<String> salaryNotes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CsvImportMatch() when $default != null:
return $default(_that.accounts,_that.categories,_that.salaryNotes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<CsvAccountMatch> accounts,  List<CsvCategoryMatch> categories,  Set<String> salaryNotes)  $default,) {final _that = this;
switch (_that) {
case _CsvImportMatch():
return $default(_that.accounts,_that.categories,_that.salaryNotes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<CsvAccountMatch> accounts,  List<CsvCategoryMatch> categories,  Set<String> salaryNotes)?  $default,) {final _that = this;
switch (_that) {
case _CsvImportMatch() when $default != null:
return $default(_that.accounts,_that.categories,_that.salaryNotes);case _:
  return null;

}
}

}

/// @nodoc


class _CsvImportMatch implements CsvImportMatch {
  const _CsvImportMatch({required  List<CsvAccountMatch> accounts, required  List<CsvCategoryMatch> categories, required  Set<String> salaryNotes}): _accounts = accounts,_categories = categories,_salaryNotes = salaryNotes;
  

 final  List<CsvAccountMatch> _accounts;
@override List<CsvAccountMatch> get accounts {
  if (_accounts is EqualUnmodifiableListView) return _accounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_accounts);
}

 final  List<CsvCategoryMatch> _categories;
@override List<CsvCategoryMatch> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

/// The Salary label of every locale, for [CsvImportPlan.salaryNotes].
 final  Set<String> _salaryNotes;
/// The Salary label of every locale, for [CsvImportPlan.salaryNotes].
@override Set<String> get salaryNotes {
  if (_salaryNotes is EqualUnmodifiableSetView) return _salaryNotes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_salaryNotes);
}


/// Create a copy of CsvImportMatch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CsvImportMatchCopyWith<_CsvImportMatch> get copyWith => __$CsvImportMatchCopyWithImpl<_CsvImportMatch>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CsvImportMatch&&const DeepCollectionEquality().equals(other.accounts, _accounts)&&const DeepCollectionEquality().equals(other.categories, _categories)&&const DeepCollectionEquality().equals(other.salaryNotes, _salaryNotes));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_accounts),const DeepCollectionEquality().hash(_categories),const DeepCollectionEquality().hash(_salaryNotes));
}

@override
String toString() {
    return 'CsvImportMatch(accounts: $accounts, categories: $categories, salaryNotes: $salaryNotes)';
}


}

/// @nodoc
abstract mixin class _$CsvImportMatchCopyWith<$Res> implements $CsvImportMatchCopyWith<$Res> {
  factory _$CsvImportMatchCopyWith(_CsvImportMatch value, $Res Function(_CsvImportMatch) _then) = __$CsvImportMatchCopyWithImpl;
@override @useResult
$Res call({
 List<CsvAccountMatch> accounts, List<CsvCategoryMatch> categories, Set<String> salaryNotes
});




}
/// @nodoc
class __$CsvImportMatchCopyWithImpl<$Res>
    implements _$CsvImportMatchCopyWith<$Res> {
  __$CsvImportMatchCopyWithImpl(this._self, this._then);

  final _CsvImportMatch _self;
  final $Res Function(_CsvImportMatch) _then;

/// Create a copy of CsvImportMatch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accounts = null,Object? categories = null,Object? salaryNotes = null,}) {
  return _then(_CsvImportMatch(
accounts: null == accounts ? _self._accounts : accounts // ignore: cast_nullable_to_non_nullable
as List<CsvAccountMatch>,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<CsvCategoryMatch>,salaryNotes: null == salaryNotes ? _self._salaryNotes : salaryNotes // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}


}

// dart format on
