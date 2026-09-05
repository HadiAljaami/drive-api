module V1
  class BlobsController < ApplicationController
    def create
      blob = Blobs::CreateBlob.new.call(
        external_id: blob_params[:id],
        encoded_data: blob_params[:data]
      )

      render json: {
        id: blob.external_id,
        size: blob.size_bytes,
        created_at: blob.created_at.utc.iso8601
      }, status: :created
    end

    def show
      render json: Blobs::RetrieveBlob.new.call(external_id: params[:id])
    end

    private

    def blob_params
      params.permit(:id, :data)
    end
  end
end