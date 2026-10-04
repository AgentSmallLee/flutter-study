import 'package:equatable/equatable.dart';
import '../../domain/entities/product_detail_entity.dart';

/// 商品详情状态
abstract class ProductDetailState extends Equatable {
  const ProductDetailState();

  @override
  List<Object> get props => [];
}

/// 初始状态
class ProductDetailInitial extends ProductDetailState {
  const ProductDetailInitial();
}

/// 加载中
class ProductDetailLoading extends ProductDetailState {
  const ProductDetailLoading();
}

/// 加载成功
class ProductDetailSuccess extends ProductDetailState {
  const ProductDetailSuccess(this.product);

  final ProductDetailEntity product;

  @override
  List<Object> get props => [product];
}

/// 加载失败
class ProductDetailFailure extends ProductDetailState {
  const ProductDetailFailure(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}
