import 'package:bloc/bloc.dart';
import '../../domain/usecases/get_product_detail_usecase.dart';
import 'product_detail_event.dart';
import 'product_detail_state.dart';

/// 商品详情 Bloc
class ProductDetailBloc
    extends Bloc<ProductDetailEvent, ProductDetailState> {
  ProductDetailBloc(this._getProductDetailUseCase)
      : super(const ProductDetailInitial()) {
    on<ProductDetailLoadEvent>(_onLoad);
  }

  final GetProductDetailUseCase _getProductDetailUseCase;

  Future<void> _onLoad(
    ProductDetailLoadEvent event,
    Emitter<ProductDetailState> emit,
  ) async {
    emit(const ProductDetailLoading());
    final result = await _getProductDetailUseCase(event.productId);
    result.fold(
      (failure) => emit(ProductDetailFailure(failure.message)),
      (product) => emit(ProductDetailSuccess(product)),
    );
  }
}
