int main(int i, char** argv)
{
#if __clang__ == 1
   return 1;
#else
   return 0;
#endif       
}
