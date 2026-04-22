from pydantic_settings import BaseSettings
from functools import lru_cache
import os


class Settings(BaseSettings):
    flask_env: str = "production"
    flask_debug: int = 0
    host_server: str = "https://zerotouchalgo.com"
    redirect_url: str = "https://zerotouchalgo.com/auth/callback"

    broker_api_key: str = ""
    broker_api_secret: str = ""
    app_key: str = "change_me_to_a_random_secret_key"

    redis_url: str = "redis://localhost:6379/0"
    sqlite_path: str = "./foss_trades.db"

    cors_origins: str = "*"
    cors_credentials: bool = True

    openblas_num_threads: int = 2
    omp_num_threads: int = 2
    mkl_num_threads: int = 2
    numexpr_num_threads: int = 2
    numba_num_threads: int = 2
    strategy_memory_limit_mb: int = 1024

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        extra = "ignore"

    @property
    def has_api_key(self) -> bool:
        return bool(self.broker_api_key and self.broker_api_secret)

    def configure_threading(self):
        os.environ.setdefault("OPENBLAS_NUM_THREADS", str(self.openblas_num_threads))
        os.environ.setdefault("OMP_NUM_THREADS", str(self.omp_num_threads))
        os.environ.setdefault("MKL_NUM_THREADS", str(self.mkl_num_threads))
        os.environ.setdefault("NUMEXPR_NUM_THREADS", str(self.numexpr_num_threads))
        os.environ.setdefault("NUMBA_NUM_THREADS", str(self.numba_num_threads))


@lru_cache()
def get_settings() -> Settings:
    return Settings()
